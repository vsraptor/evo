#!/usr/bin/env ruby

#calculate DIRECT distance given longitude and latidude, keeping in mind the curvature of Earth
# Oto Brglez : stackoverflow.com
def distance loc1, loc2
  rad_per_deg = Math::PI/180  # PI / 180
  rkm = 6371                  # Earth radius in kilometers
  rm = rkm * 1000             # Radius in meters

  dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
  dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

  lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
  lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

  a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
  c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

  rm * c / 1000 # Delta in km
end

#randomly swap two characters in the string
def mutate path
	mutated = path.dup
	pos1 = rand(mutated.size)
	pos2 = rand(mutated.size)
	tmp = mutated[pos1]
	mutated[pos1] = mutated[pos2]
	mutated[pos2] = tmp
	return mutated
end

#crossover two strings
def mate str1, str2
	new_str = " " * str1.size
	start = rand(str1.size-1)
	stop  = rand(str1.size-1)
	start,stop = stop,start	if start > stop
	#pick random chunk from str1
	new_str[start .. stop] = str1[start .. stop]
	#pick items from str2, but make sure there is no char repetition in the new str
	j = 0 #index in str2
	for i in 0 .. new_str.size-1
		if new_str[i] == ' ' #no data yet
			while new_str.index str2[j]; j += 1 end
			new_str[i] = str2[j]
			j += 1
		end
	end
	return new_str
end

class TSP
	attr_accessor :pool

	def initialize a={}
		@pool = []
		@display_every = a[:display_every] || 0
		@iterations = a[:iterations] || 1000

		#parse cities locations string. Format: mnemonic,city_name,longitude,latitude;... repeat...
		@cities = {}
		@mnemonics = [] #used to generate random paths

		if a[:cities] #did you provide cities
			#cleanup the string
			a[:cities].gsub! /[^\d\.,;_\w]/, ''

			for line in a[:cities].split(';')
				tmp = line.split(',')
				mnemonic = (tmp.shift)[0] #single character
				@mnemonics.push mnemonic
				name = tmp.shift
				@cities[mnemonic] = [ name, *tmp.map(&:to_f) ]
			end
		else
			gen_random_cities #if no cities are provided
		end
		#p @cities
		#p @mnemonics
	end

	#total number of paths : (n-1)!/2
	def display_best_solution
		best = @pool[-1]
		str = ''
		best[:data].split('').each do |ch|
			str += @cities[ch][0] + ' => '
		end

		puts
		puts "> Best path : #{best[:data]}, length : #{best[:fitness].to_i} km"
		puts "> Route :\n" + str[0 .. -4]
		puts

		return best
	end

	def list_distances
		for m in 0 .. @mnemonics.size - 1
			for n in m .. @mnemonics.size - 1
				next if m == n
				c1,c2 = @cities[ @mnemonics[m] ] , @cities[ @mnemonics[n] ]
				d = distance c1[1,2], c2[1,2]
				puts "#{c1[0]} => #{c2[0]} : #{d}"
			end
		end
	end

	def gen_random_cities cnt=20, height=100, width=100
		chars = [ *('a' .. 'z'), *('A' .. 'Z')]
		for i in 1 .. cnt
			name = 'C' + i.to_s
			@mnemonics.push chars[i-1]
			@cities[ chars[i-1] ] = [ name, rand(height), rand(width) ]
		end
		return @cities
	end

	def random_path size=@mnemonics.size
		return @mnemonics.shuffle[0 .. size-1].join('')
	end

	#using the @cities coord calc the traveling path, smaller better
	def fitness path
		d = 0
		for ci in 0 .. path.size - 2
			c1 = @cities[ path[ci] ]
			c2 = @cities[ path[ci + 1] ]
			d += distance c1[1,2], c2[1,2]
		end
#		puts "dist> #{d}"
		return d
	end

	def add2pool str
		fit_score = fitness str
		@pool.push( { data: str, fitness: fit_score } )
	end

	def gen_pool len
		@pool = []
		for i in 1 .. len
			add2pool random_path
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

	def replace mutated
		fit_score = fitness mutated

		#die off, replace the worse parent with the child (if better)
		if @pool[0][:fitness] > fit_score
			@pool[0] = { data: mutated, fitness: fit_score }
		end
	end

	def evolve iter
		#insure that pool is sorted, higher -> lower
		@pool.sort_by! { |e| -e[:fitness] } #reverse order by fitness

		### SELECTION ###
		parent1, parent2 = pick_parents

		### CROSSOVER ###
		#the pool is sorted, worse -to-> good
		child = mate @pool[parent1][:data], @pool[parent2][:data]

		### MUTATION ###
		mutated = mutate child

		if not @display_every.zero?
			display_pool if iter % @display_every == 0
		end

		replace mutated

	end

	def iterate iterations=@iterations
		raise "Please generate gene pool first" if @pool.size == 0
		raise "Please generate or provide city list" if @cities.size == 0
		for i in 1 .. iterations
			evolve i
		end
	end

end
