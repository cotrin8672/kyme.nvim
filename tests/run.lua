local cwd = vim.fn.getcwd()
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	cwd .. "/?.lua",
	cwd .. "/?/init.lua",
	package.path,
}, ";")

local specs = {
	"tests.source_mise_spec",
	"tests.execution_spec",
}

local failures = {}
local total = 0

for _, spec_name in ipairs(specs) do
	local tests = require(spec_name)

	for _, test in ipairs(tests) do
		total = total + 1
		local ok, err = pcall(test.fn)

		if ok then
			print(("ok %d - %s"):format(total, test.name))
		else
			table.insert(failures, {
				name = test.name,
				err = err,
			})
			print(("not ok %d - %s"):format(total, test.name))
		end
	end
end

if #failures > 0 then
	for _, failure in ipairs(failures) do
		print("")
		print(("FAILED: %s"):format(failure.name))
		print(failure.err)
	end

	error(("%d of %d tests failed"):format(#failures, total))
end

print(("%d tests passed"):format(total))
