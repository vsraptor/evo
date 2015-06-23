require 'tree'
require_relative 'random_gaussian'

class TreeExpr

	OPS  = [ '+', '-', '*', '/']#, '**' ]
	FUNS = [ 'Math.sqrt', 'Math.log2', 'Math.exp']#, 'Math.sin' ]

	attr_accessor :root, :eval_mode, :vars

	def initialize a={}
		@root = nil
		@vars = nil
		@do_fun = a[:do_fun]

	end

	#called when you dup/clone the object (this implement deep copy)
	def initialize_copy orig
		super
		@vars = @vars.dup
		#detached_subtree_copy()
		@root = @root.dup #make sure to copy the tree
	end

	def rand_op; OPS.sample end
	def rand_fun; FUNS.sample end
	def rand_var; @vars.sample end

	#used to generate random names for vars,ops and functions. Tree-class requires unique names
	def rand_str size=10
		('a'..'z').to_a.shuffle[0,size].join
	end

	def create_node name, data, type
		return Tree::TreeNode.new(name, { data: data, type: type, display: data })
	end

	def add_node parent, name, data, type
		node = create_node name, data, type
		if parent == nil
			@root = node
		else
			parent << node
		end
		return node
	end

	#for now just fuctionssingle argument
	def leaf_function parent, vars
		#random number of random arguments
		args = vars  #vars.sample( rand vars.size )
		fun_name = 'f_' + rand_str
		fun_node = add_node parent, fun_name, rand_fun, :fun
		add_node fun_node, rand_str, args[0], :var
		return fun_node
	end

	def create_subexpr parent, depth
		op = rand_op
		var1 = rand_var
		var2 = rand_var

		op_name = 'o_' + rand_str
		op_node = add_node parent, op_name, op, :op

		if depth <= 1

			if @do_fun && rand(3) > 1 #random true or false, slanted towards arithmetic exp
				leaf_function op_node, [ var1 ] #!fixme for now only one arg funs
			else
				add_node op_node, rand_str , var1, :var
			end

			if @do_fun && rand(3) > 1 #random true or false
				leaf_function op_node, [ var2 ] #!fixme for now only one arg
			else
				add_node op_node, rand_str, var2, :var
			end

		else
			create_subexpr op_node, depth - 1
			create_subexpr op_node, depth - 1
		end
	end

	def gen_random_expr a={}
		#if no variable names are provided
		if a[:var_count] && a[:vars] == nil
			a[:vars] = []
			a[:var_count].times do |i|
				a[:vars].push 'x' + i.to_s
			end
		end

		@vars = a[:vars] #remember vars for reference and reuse

		depth = rand a[:max_depth]
		create_subexpr a[:parent], depth
	end

	#for display purposes returns var_name, for eval purposes returns args['var_name']
	def n2h el #var name to hash key
		return "args['" + el[:data] + "']" if el[:type] == :var && @eval_mode == :args
		el[:data]
	end

	#converting the tree-expr to a string-expr that can thne be evaluated by Ruby eval()
	def listify node=@root
		if node.has_children? #op or function
			if node.children.length == 2 && node.content[:data] =~ /[\/*+-]|(\*\*)/ #process operators
				return [ '(', listify(node.first_child), n2h(node.content), listify(node.last_child) , ')' ]
			end
			if node.children.length == 1 && node.content[:type] == :fun #function
				return [ n2h(node.content) , '(', listify(node.children[0]) , ')' ]
			end
		else #leaf
			return n2h(node.content)
		end
	end

	def to_s
		listify.flatten.join('')
	end

	def expr_str
		tmp = @eval_mode
		@eval_mode = :args
		str = listify.flatten.join('')
		@eval_mode = tmp
		return str
	end

	def dump node=@root
		puts node.print_tree 0, nil, lambda { |node, prefix| puts "#{prefix} #{node.content[:display]}" }
	end

	#calculate the expression, expect named argument that match @vars (args passed as Hash)
	def calc args
		rv = begin
			eval expr_str
		rescue ZeroDivisionError
			9999999 #Float::INFINITY  #!fixme
		rescue Math::DomainError #for sqrt() and log2()
			9999999
		end
		rv = 0.0 if rv.to_f.nan?
		return rv
	end

end


class EvoExpr
	attr_accessor :pool

	def initialize a={}
		#!fixme : vars required !!? may be
		a = { pool_size: 10, max_depth: 2, debug: true, do_fun: false, display_every: 1000, mutation_count: 3,
				drop_node_count: 10, max_children: 3, min_fitness: 0.0, max_mate_pairs: 3 }.merge(a)
		raise "Please provide [input] and [output] data sets" if a[:input].nil? || a[:output].nil?
		@pool = [] #expressions pool
		@input = a[:input] #input data of the unknown expression
		@output = a[:output] #output data of the unknown expression
		@vars = a[:vars]
		@debug = a[:debug]
		@do_fun = a[:do_fun]
		@display_every = a[:display_every]
		@drop_node_count = a[:drop_node_count] #cut the tree if it become too deep
		@max_children = a[:max_children] #the number of children parents can have per iteration
		@max_mate_pairs = a[:max_mate_pairs] #how many parent pairs mate in a cycle
		@min_fitness = a[:min_fitness] #what fitness is considered a match
		@mutation_count = a[:mutation_count] 

		gen_pool a[:pool_size], a[:max_depth]
	end

	#generate random tree-expression for the pool
	def random_expr args={}
		args = { vars: @vars, max_depth: 2 }.merge(args)
		te = TreeExpr.new do_fun: @do_fun
		te.gen_random_expr args
		return te
	end

	#calculate avg difference between the original outputs and the expression
	def fitness expr
		outs = @input.map do |ins|
			args = {}
			#build argument hash
			ins.each_with_index { |v,idx| args[ @vars[idx] ] = v }
			expr.calc(args) #calculate the function
		end
		#Calculate Mean Squared Error (MSE)
		diffs = @output.zip(outs).map { |x,y| (x-y)**2 }
		return  diffs.reduce(:+) / @output.size.to_f
	end


	def add2pool expr
		fit_score = fitness expr
		@pool.push( { expr: expr, fitness: fit_score, generation: 0 } )
	end

	def gen_pool size, max_depth
		@pool = []
		size.times { add2pool random_expr(max_depth: max_depth) }
	end

	def display_pool iter=0
		puts "pool #{iter}>>"
		@pool.each do |te|
			print '> ' + te[:expr].to_s
			puts " :  #{te[:fitness]}, gen:#{te[:generation]}"
		end
		puts 'end <<'
	end

	#simple mutation pick random op,fun or var and may be change it
	def mutate expr
		new_expr = expr.dup

		@mutation_count.times do

			node = pick_rand_node new_expr
			print "before> #{node.content} : " if @debug
			puts new_expr.to_s if @debug

			case node.content[:type]
			when :op
					node.content[:data] = new_expr.rand_op
			when :var
				node.content[:data] = new_expr.rand_var
			when :fun
				node.content[:data] = new_expr.rand_fun
			end

			#reset also the display symbol
			node.content[:display] = node.content[:data]
			if @debug
				print "after> #{node.content} : "
				puts new_expr.to_s
			end
		end
		return new_expr
	end

	#look for random node for slicing&dicing
	def pick_rand_node expr, from=2
		size = expr.root.size
		#we want the selected nodes to be mostly in the middle i.e. cut where the tree is deeper! sort of
		rg = RandomGaussian.new(size/2,size/10)
		pos = rg.rand.to_i()
		pos = from if pos < from  # 2 .. will skip root
		#pos = rand(from .. expr.root.size) # uniform random
		puts "pos> #{pos}" if @debug
		#reach the node at position
		return expr.root.first(pos).last
	end

	#look for random function or operator
	def pick_funop expr, skip=2
		node = pick_rand_node expr, skip
		return node.parent if node.content[:type] == :var
		return node
	end

	#drop random part of the expression tree
	def drop_rand_part expr, skip=3
		node = pick_funop expr, skip
		return if node.is_root? || node.parent.is_root?
		parent = node.parent #we will need the parent ->
		node.remove_all!
		node.remove_from_parent!
		#-> to replace the emptied op/fun with random variable
		expr.add_node parent, expr.rand_str, expr.rand_var, :var
	end

	#Install part of expr2 at random place into expr1 (replacing)
	def mate expr1, expr2
		new_expr = expr1.dup #deep copy
		new_expr.dump if @debug

		#pick two random places in the mating expressions for crossover
		node1 = pick_rand_node new_expr
		node2 = pick_funop expr2 #we want functional expression i.e. op/fun not var

		sub_tree2 = node2.dup #detached_subtree_copy
		#make sure we don't cause duplicate named siblings when coping subtrees back and forth
		sub_tree2.rename(new_expr.rand_str)
		sub_tree2.print_tree( 0, nil, lambda { |node, prefix| puts "#{prefix} #{node.content[:display]}" } ) if @debug
		#replace part of expr1 sub tree with another one from expr2
		node1.replace_with sub_tree2

		#if the expression is too 'deep' drop part of it
		#depth = new_expr.root.node_height
		node_count = new_expr.root.size
		puts "depth-nc> #{node_count}" if @debug
		drop_rand_part new_expr if node_count >= @drop_node_count

		if @debug
			puts '-----------------------'
			new_expr.dump
			puts new_expr.to_s
		end

		return new_expr
	end

	#pick parent with tendency of smaller fitness i.e. close to target
	def rand_parent range; ((rand * rand * rand) * range).to_i end
	def pick_parents
		range = @pool.size
		pidx1 = rand_parent range
		pidx2 = rand_parent range
		#just quick precaution so that we dont pick the same parent twice, !most of the times
		pidx2 = pidx1 == pidx2 ? rand_parent(range) : pidx2
		puts "parents> #{pidx1} , #{pidx2}" if @debug
		return pidx1,pidx2
	end

	#insert the new expression in the pool based on fitness
	def insert2pool offspring, iter
		fit_score = fitness offspring
		#first find the correct positon
		idx = @pool.index { |f| f[:fitness] < fit_score }
		idx = idx.nil? ? -1 : idx #new fitness smaller than all, add at the end
		@pool.insert( idx, { expr: offspring, fitness: fit_score, generation: iter } )
	end


	def evolve iter

		#how many pairs will mate
		pair_count = rand(@max_mate_pairs)
		offsprings = []

		pair_count.times do #how many couples will mate

			### SELECTION ###
			parent1, parent2 = pick_parents

			children_count = rand(@max_children)
			children_count.times do #how many children will be born

				### CROSSOVER ###
				child = mate @pool[parent1][:expr], @pool[parent2][:expr]
				### MUTATION ###
				offsprings.push( mutate child ) #collect offsprings for processing
				#we do this so that children cant become parent in the same iteration

			end

		end

		#put the offsprings in the correct place, so we dont re-sort the pool
		offsprings.each {|o|	insert2pool o, iter }

		#remove the the elements with worst fitness
		@pool.shift offsprings.size

		#does any of the new children have the fitness we are looking for
		return :found if @pool[-1][:fitness] < @min_fitness

	end


	def iterate iterations
		raise "Please generate gene pool first" if @pool.size == 0

		#insure that pool is sorted, higher -> lower fitness
		@pool.sort_by! { |e| -e[:fitness] }

		for i in 1 .. iterations
			puts "=" * 80 if @debug
			unless @display_every.zero?
				display_pool i if i % @display_every == 0
			end
			return { best_match: @pool[-1], iter: i, found: true } if evolve(i) == :found
		end
		return { best_match: @pool[-1], iter: i, found: false }
	end

end


__END__


