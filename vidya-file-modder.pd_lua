
local FileModder = pd.Class:new():register("vidya-file-modder")

function FileModder:initialize(sel, atoms)

	-- 1. Object-triggering bang
	-- 2. Incoming single data bytes from [binfile]
	-- 3. Total bytes in file, from [route buflength]
	-- 4. Glitch type
	-- 5. Glitch point
	-- 6. Active filename
	self.inlets = 6
	
	-- 1. To [binfile] inlet - bang(get next byte), clear(clear the buffer), FLOAT(write a byte to buffer), write(write to file)
	self.outlets = 1
	
	-- Currently active file's namedata
	self.filedata = {
		"default-filename",
		0,
	}
	
	-- Glitch type (pattern, random, or splice)
	self.glitchtype = "random"
	
	-- Minimum glitch point in image data
	self.glitchpoint = 500
	
	-- Hold all bytes, which are converted to ints in the 0-255 range
	self.bytebuffer = {}
	
	-- Buffer length of currently active file
	self.buflength = 0
	
	return true

end

function FileModder:in_1_bang()

	for i = 1, self.buflength do
		self:outlet(1, "bang", {})
	end
	
	self:outlet(1, "clear", {})
	
	if self.glitchtype == "pattern" then
	
		local plen = math.random(2, 1000)
		local patbuffer = {}
		
		for i = 1, plen do
			table.insert(patbuffer, math.random(1, 254))
		end
		
		for i = self.glitchpoint, self.buflength do
			self.bytebuffer[i] = patbuffer[((i - 1) % #patbuffer) + 1]
		end
		
	elseif self.glitchtype == "random" then
	
		for i = 1, 20 do
			self.bytebuffer[math.random(self.glitchpoint, self.buflength)] = math.random(1, 244)
		end
		
	elseif self.glitchtype == "splice" then
		
		local sloc = math.random(self.glitchpoint, self.buflength)
		local schunksize = math.random(1, self.buflength - sloc)
		local splicebuffer = {}
		for i = 1, schunksize do
			table.insert(splicebuffer, table.remove(self.bytebuffer, sloc))
		end
		
		local insertpoint = math.random(self.glitchpoint, #self.bytebuffer)
		for _, v in ipairs(splicebuffer) do
			table.insert(self.bytebuffer, insertpoint, v)
		end
		
	end

	for _, v in ipairs(self.bytebuffer) do
		self:outlet(1, "float", {v})
	end
	
	local outname = self.filedata[1] .. "-glitch" .. self.filedata[2] .. ".jpeg"
	self:outlet(1, "write", {outname})
	pd.post("New glitched image: " .. outname)
	
	self:outlet(1, "clear", {})
	
	self.bytebuffer = {}

end

function FileModder:in_2_float(f)
	table.insert(self.bytebuffer, f)
end

function FileModder:in_3_list(f)
	self.buflength = f[1] + 1 -- Shift from 0-indexed to 1-indexed
end

function FileModder:in_4_list(d)
	self.glitchtype = d[1]
end

function FileModder:in_5_float(f)
	self.glitchpoint = f
end

function FileModder:in_6_list(d)
	self.filedata = {d[1], d[2]}
end
