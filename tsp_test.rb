require_relative 'lib/tsp'

DISPLAY = 0

def hr; puts; puts '-' * 80; puts end

def test a={}
	e = TSP.new(iterations: a[:iters], display_every: DISPLAY, cities: a[:cities])
	e.gen_pool a[:pool_size]
	e.iterate
	#e.list_distances
	e.display_best_solution
	return e
end

def loop_over a={}
	e = nil
	for i in (1000 .. 10_000).step(1000)
		a[:iters] = i
		puts "Total iterations> #{i} ============================================"
		e = test a
	end
	hr
	e.draw_graph_paths width: 800, height: 600, hmirror: a[:hmirror], vmirror: a[:vmirror], padding: 30 if a[:graph]
	return e
end

#FORMAT FOR CITIES string is :
# mnemonic,name,longitude,latitude;.....

def cities opt, graph

	p opt, graph
	#first try all cities spread over USA, should be easy to figure out if the correct tour was picked
	cities = 'd,DC,77.01,38.90;l,Los_Angeles,118.25,34.05;c,Chicago,87.68,41.83;m,Memphis,89.97,35.11;h,Houston,95.36,29.76;
				 L,Las_Vegas,115.17,36.12;k,Kansas_city,94.57,39.09;M,Miami,80.20,25.77;s,San_Fran,122.41,37.78;a,Dallas,96.79,32.77;
			 	 n,Nashville,86.78,36.16;e,Detroit,83.04,42.33;p,Phoneix,112.06,33.45;D,Denver,104.99,39.73'

	loop_over cities: cities, pool_size: 30, graph: graph, vmirror: true, hmirror: true  if opt == '1'

	#Now add sort of a loop in California
	cities += ';S,Sacramento,121.46,38.55;f,Fresno,119.76,36.75;A,San_jose,121.88,37.33;C,Carson_city,119.75,39.16'
	loop_over cities: cities, pool_size: 30, graph: graph, vmirror: true, hmirror: true  if opt == '2'

	#Now try with randomly generated cities
	if opt == '3' or opt.nil?
		cities = nil
		loop_over cities: cities, pool_size: 30, graph: graph
	end

end

cities ARGV[0], true

