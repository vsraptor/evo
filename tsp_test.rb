require_relative 'lib/tsp'

DISPLAY = 0

def hr; puts; puts '-' * 80; puts end

def test a={}
	e = TSP.new(iterations: a[:iters], display_every: DISPLAY, cities: a[:cities])
	e.gen_pool a[:pool_size]
	e.iterate
	#e.list_distances
	e.display_best_solution
end

def loop_over a={}
	for i in (1000 .. 10000).step(1000)
		a[:iters] = i
		puts "Total iterations> #{i} ============================================"
		test a
	end
end

def draw_graph_paths
	begin
		require 'green_shoes'
		puts "> Drawing the graph ..."
	rescue LoadError
		puts "lib not installed"
	end
end

#FORMAT FOR CITIES string is :
# mnemonic,name,longitude,latitude;.....

#first try all cities spread over USA, should be easy to figure out if the correct tour was picked
cities = 'd,DC,38.90,77.01;l,Los_Angeles,34.05,118.25;c,Chicago,41.83,87.68;m,Memphis,35.11,89.97;h,Houston,29.76,95.36;
			 L,Las_Vegas,36.12,115.17;k,Kansas_city,39.09,94.57;M,Miami,25.77,80.20;s,San_Fran,37.78,122.41;a,Dallas,32.77,96.79;
		 	 n,Nashville,36.16,86.78;e,Detroit,42.33,83.04;p,Phoneix,33.45,112.06;D,Denver,39.73,104.99'
#loop_over cities: cities, pool_size: 30

hr

#Now add sort of a loop in California
cities += ';S,Sacramento,38.55,121.46;f,Fresno,36.75,119.76;A,San_jose,37.33,121.88;C,Carson_city,39.16,119.75'
#loop_over cities: cities, pool_size: 30

hr

#Now try with randomly generated cities
cities = nil
loop_over cities: cities, pool_size: 30

