c = arg[1] or 11

function e(com)
	print('$'..com)
	os.execute(com)
end

for i = 0,c-1 do
	e('diff -U1000 '..i..'.lua '..(i+1)..'.lua > '..(i+1)..'.patch')
end
