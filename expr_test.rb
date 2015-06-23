#!/usr/bin/env ruby
require_relative 'lib/evo_expressions'

#test functions, keep them single line
def two1 a; a[0] + a[1] end
def two2 a; a[0] - a[1] end
def two3 a; a[0] + Math.sqrt(a[1]) end
def two4 a; a[0] * a[1] end
def two5 a; a[0] * (a[1]-a[0]) + a[0] end
def three1 a; a[0] - a[1]/a[2] end
def three2 a; a[0]/a[2] + a[1] end
def three3 a; a[0] - a[1] + a[2] end
def three4 a; Math.exp(a[0]) - a[1] + a[2] end
def four1 a; a[0] + a[1] - a[2] + a[3] end
def four2 a; a[0] + a[1] - a[2] * a[3] end
def four3 a; a[0] / a[1] - a[2] + a[3] end
def four4 a; a[0] / a[1] - a[2] * a[3] end
def four5 a; a[0] / a[1] - a[2] * Math.sqrt(a[3]) end
def five1 a; a[0]+ (a[4] / a[1]) - a[2] * a[3] end
def five2 a; a[0]+ a[4] - a[1] - a[2] + a[3] end


#read source of this script and find the definition
def fun_def fun
	DATA.rewind
	DATA.readlines.each do |line|
		return line if line =~ /#{fun}/
	end
end

def gen_input_data size, min=0.1, max=100.0, var_count=3
	(1 .. size).map { var_count.times.map { rand(min .. max) } }
end

def gen_output_data fun, input
	output = input.map do |a|
		fun.call a
	end
	return output
end

def test a={}
	a = {
			fun: :two1, data_points: 100, from: 0.1, to: 100, var_count: 4,
			max_depth: 5, drop_node_count: 10, children: 3, fitness: 20,
			pairs: 5, d: false, do_fun: false, every: 1000,
			iters: 10_000,
		 }.merge(a)

	case a[:fun].to_s
	when /^two/
		a[:var_count] = 2
	when /^three/
		a[:var_count] = 3
	when /^four/
		a[:var_count] = 4
	when /^five/
		a[:var_count] = 5
	end

	#if no variable names are provided
	if a[:vars] == nil
		a[:vars] = []
		(a[:var_count]).times do |i|
			a[:vars].push 'x' + i.to_s
		end
	end

	input = gen_input_data a[:data_points], a[:from], a[:to], a[:var_count]
	output = gen_output_data method(a[:fun]), input

	e = EvoExpr.new pool_size: 200, input: input, output: output, vars: a[:vars],
						 max_depth: a[:max_depth], drop_node_count: a[:drop_node_count], max_children: a[:children], min_fitness: a[:fitness],
						 max_mate_pairs: a[:pairs], debug: a[:d], do_fun: a[:do_fun], display_every: a[:every]

	rv = e.iterate a[:iters]
	puts '*' * 80
	e.display_pool
	puts
	puts rv
	puts
	puts "Using variables : #{a[:vars]}"
end


#pick test function
fun = ARGV[0].to_sym unless ARGV[0].nil?
fun ||= :three1

test fun: fun, iters: 10000, every: 500, drop_node_count: 10, max_depth: 4
#try this too
#test fun: fun, do_fun: true, fitness: 100, every: 200, d: false, iters: 10_000
puts "Using function: #{fun}()"
puts fun_def(fun)


__END__

