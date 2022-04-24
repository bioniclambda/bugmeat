STACK_LIMIT = 256
LABEL_LIMIT = 16

stack = {}
stackpos = 1
str_stack = {}
str_stackpos = 1

labels = {}

for i = 1, LABEL_LIMIT, 1 do
	labels[i] = 0
end

FLAG_ZERO = false
FLAG_EQUAL = false
FLAG_GREATER = false
FLAG_LESSER = false
FLAG_NEG = false

function stack:push(val)
	if (type(val) ~= 'number') then
		return
	end

	if (stackpos >= STACK_LIMIT) then
		return
	end
	
	stack[stackpos] = val;
	stackpos = stackpos + 1
end

function stack:pop()
	if (stackpos == 1) then -- Stack is empty. Arrays start at 1 in Lua
		return 0
	end
	
	local val = stack[stackpos - 1]
	stackpos = stackpos - 1
	return val
end

function stack:swap()
	if (stackpos < 3) then -- Stack is too short to swap. Arrays start at 1 in Lua
		return
	end

	local val0 = stack:pop()
	local val1 = stack:pop()

	stack:push(val0)
	stack:push(val1)
end

function stack:dup()
	stack:push(stack[stackpos - 1])
end

function stack:peek()
	return stack[stackpos - 1]
end

function str_stack:push(str)
	if (type(str) ~= 'string') then
		return
	end

	if (str_stackpos >= STACK_LIMIT) then
		return
	end
	
	str_stack[str_stackpos] = str;
	str_stackpos = str_stackpos + 1
end

function str_stack:pop()
	if (str_stackpos == 1) then -- Stack is empty. Arrays start at 1 in Lua
		return ''
	end
	
	local str = str_stack[str_stackpos - 1]
	str_stackpos = str_stackpos - 1
	return str
end

function str_stack:swap()
	if (str_stackpos < 3) then -- Stack is too short to swap. Arrays start at 1 in Lua
		return
	end

	local str0 = str_stack:pop()
	local str1 = str_stack:pop()

	str_stack:push(str0)
	str_stack:push(str1)
end

function stack:peek()
	return stack[stackpos - 1]
end

function split(s, delimiter)
	local result = {}

	for match in (s..delimiter):gmatch('(.-)'..delimiter) do
		table.insert(result, match)
	end

	return result
end


function interpret(file)
	local sourcefile = io.open(file, 'r')
	local content = sourcefile:read('*a')
	local tokens = split(content, ' ')

	local is_num = false

	local index = 1

	while (index <= #tokens) do
		local token = tokens[index]
		token = token:gsub('\n', '')
		
		-- Number
		if (string.match(token, '%d')) then
			stack:push(tonumber(token))

		-- String
		elseif (string.match(token, '\'*\'')) then
			str_stack:push(token:gsub('\'', ''))

		elseif (string.match(token, 'HALT')) then
			print('!')
			break

		elseif (token == 'ADD' or token == '+') then
			val1 = stack:peek()
			stack:swap()
			val0 = stack:peek()
		
			if ((stack:peek() + stack:peek()) < 0) then
				FLAG_NEG = true
			else
				FLAG_NEG = false
			end

			if ((stack:peek() + stack:peek()) == 0) then
				FLAG_ZERO = true
			else
				FLAG_ZERO = false
			end

			stack:push(stack:pop() + stack:pop())
		
		elseif (token == 'SUB' or token == '-') then
				val1 = stack:peek()
				stack:swap()
				val0 = stack:peek()
			
				if ((stack:peek() - stack:peek()) < 0) then
					FLAG_NEG = true
				else
					FLAG_NEG = false
				end

				if ((stack:peek() - stack:peek()) == 0) then
					FLAG_ZERO = true
				else
					FLAG_ZERO = false
				end
				
				stack:push(stack:pop() - stack:pop())
		
		elseif (token == 'MUL' or token == '*') then
			val1 = stack:peek()
			stack:swap()
			val0 = stack:peek()
		
			if ((stack:peek() + stack:peek()) < 0) then
				FLAG_NEG = true
			else
				FLAG_NEG = false
			end

			if ((stack:peek() + stack:peek()) == 0) then
				FLAG_ZERO = true
			else
				FLAG_ZERO = false
			end
			
			stack:push(stack:pop() * stack:pop())
		
		elseif (token == 'DIV' or token == '/') then
			val1 = stack:peek()
			stack:swap()
			val0 = stack:peek()
		
			if ((stack:peek() + stack:peek()) < 0) then
				FLAG_NEG = true
			else
				FLAG_NEG = false
			end

			if ((stack:peek() + stack:peek()) == 0) then
				FLAG_ZERO = true
			else
				FLAG_ZERO = false
			end
			
			stack:push(stack:pop() / stack:pop())

		elseif (token == 'MOD' or token == '%') then
			val1 = stack:peek()
			stack:swap()
			val0 = stack:peek()
		
			if ((stack:peek() + stack:peek()) < 0) then
				FLAG_NEG = true
			else
				FLAG_NEG = false
			end

			if ((stack:peek() + stack:peek()) == 0) then
				FLAG_ZERO = true
			else
				FLAG_ZERO = false
			end
			
			stack:push(stack:pop() % stack:pop())

		elseif (token == 'ECHO' or token == '.') then
			io.write(stack:pop())
		
		elseif (token == 'SWAP') then
			stack:swap()

		elseif (token == 'DUP') then
			stack:dup()

		elseif (token == 'DROP') then
			stack = {}
			stackpos = 1

		elseif (token == 'DUMP') then
			for item = 1, #stack, 1 do
				print(stack[item])
			end

		elseif (token == 'LBL') then
			if (stack:peek() > 0 and stack:peek() <= LABEL_LIMIT) then
				labels[stack:pop()] = index -- we do not need to increase it, as the code that sets the index will already increase it!
			end

		elseif (token == 'CMP') then
			FLAG_EQUAL = false
			FLAG_GREATER = false
			FLAG_LESSER = false
			
			val1 = stack:pop()
			val0 = stack:pop()
			if (val0 == val1) then
				FLAG_EQUAL = true

			elseif (val0 > val1) then
				FLAG_GREATER = true
				FLAG_LESSER = false
			
			elseif (val0 < val1) then
				FLAG_GREATER = false
				FLAG_LESSER = true
			end

		elseif (token == 'JMP') then
			index = labels[stack:pop()]
			
		elseif (token == 'JNZ') then
			if (not FLAG_ZERO) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JIZ') then
			if (FLAG_ZERO) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JIE') then
			if (FLAG_EQUAL) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JNE') then
			if (not FLAG_EQUAL) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JIG') then
			if (FLAG_GREATER) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JIL') then
			if (FLAG_LESSER) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JGE') then
			if (FLAG_GREATER or FLAG_EQUAL) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JLE') then
			if (FLAG_LESSER or FLAG_EQUAL) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JIP') then
			if (not FLAG_NEG) then
				index = labels[stack:pop()]
			end

		elseif (token == 'JIN') then
			if (FLAG_NEG) then
				index = labels[stack:pop()]
			end

		elseif (token == 'PUTC') then
			io.write(string.char(stack:pop()))

		elseif (token == 'PUTS') then
			io.write(str_stack:pop())
		
		end
		
		index = index + 1
	end

	sourcefile:close()

end

interpret(arg[1])
