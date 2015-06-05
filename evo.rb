#all characters available for building our strings
CHARS = [ *('a' .. 'z'), *('A' .. 'Z'), ' ']

def random_char
	return CHARS[rand(CHARS.size-1)]
end

#return random variation for mutation
def variation var
	rand(-var .. var)
end

#randomly change one character in the string
def mutate str, var=1
	mutated = str.dup
	pos = rand(mutated.size)
	ch = mutated[pos]
	#mutate the charater at pos
	mutated[pos] = (ch.ord + variation(var) ).chr
	return mutated
end

#use only characters from the target string, for mutation
def mutate4target str, target
	mutated = str.dup
	target_chars = target.split('').uniq
	pos = rand(mutated.size)
	ch = mutated[pos]
	mutated[pos] = target_chars[rand(target_chars.size)]
	return mutated
end

def fitness str1, str2
	dist = 0
	for i in 0 .. str1.size-1
		dist += (str1[i].ord - str2[i].ord) ** 2
	end
	return dist
end

#crossover two strings
def mate str1, str2
	new_str = str1.dup
	start = rand(str1.size-1)
	stop  = rand(str1.size-1)
	start,stop = stop,start	if start > stop
	new_str[start,stop] = str2[start,stop]
	return new_str
end

class Evo
	attr_accessor :target, :pool, :found_at, :mutation, :mutation_variation

	def initialize target, a={}
		@target = target
		@pool = []
		@display_every = a[:display_every] || 10
		@iterations = a[:iterations] || 100
		@found_at = a[:found_at] || 0
		@mutation = a[:mutation] || :basic
		@mutation_variation = a[:mutation_variation] || 1
	end

	def add2pool str
		f = fitness @target, str
		@pool.push Hash[ :data => str, :fitness => f ]
	end

	def gen_pool len
		@pool = []
		for i in 1 .. len
			str = ''
			for _ in 1 .. @target.size ; str += random_char end
			self.add2pool str
		end
	end

	def display_pool
		puts "pool> " + (@pool.map {|e| e[:data]}   ).join(",")
#		puts "fit > " + (@pool.map {|e| e[:fitness]}).join(",")
	end

	#pick parent with tendency of smaller fitness i.e. close to target
	def rand_parent range; ((rand * rand) * range).to_i end
	def pick_parents
		range = @pool.size #-1
		pidx1 = rand_parent range
		pidx2 = rand_parent range
		#just quick precaution so that we dont pick the same parent twice
		pidx2 = pidx1 == pidx2 ? rand_parent(range) : pidx2

		return pidx1,pidx2
	end

	def evolve
		#insure that pool is sorted
		@pool.sort_by! { |e| -e[:fitness] } #reverse order by fitness
		parent1, parent2 = pick_parents
		#did we find match
		return true if @pool[0][:fitness] == 0
		#the pool is sorted, worse -to-> good
		child = mate @pool[parent1][:data], @pool[parent2][:data]
		#pick different mutation methods
		if @mutation == :basic
			mutated = mutate child
		else
			mutated = mutate4target child, @target
		end
		#puts "ev> " + @pool[parent1][:data] + " : " + @pool[parent2][:data] + ' = ' + mutated
		fit_score = fitness @target, mutated
		#die off, replace the worse parent with the child (if better)
		if @pool[0][:fitness] > fit_score
			@pool[0] = Hash[:data => mutated, :fitness => fit_score ]
		end

		return false
	end

	def iterate
		raise "Please generate gene pool first" if @pool.size == 0
		for i in 1 .. @iterations
			#puts ">#{i}"
			if evolve
				@found_at = i
				return i
			end
			display_pool if i % @display_every == 0
		end
		return false
	end

end

e = Evo.new(target = 'hello', iterations: 9000, display_every: 100, mutation_variation: 1)
e.gen_pool 20
e.display_pool

at = e.iterate
if at
	puts "evolved match #{at}: #{e.pool[0]}"
else
	puts "unable to evolve"
end
puts "mutation method : #{e.mutation} , #{e.mutation_variation}"
