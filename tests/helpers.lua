local M = {}

function M.same(expected, actual, message)
	if vim.deep_equal(expected, actual) then
		return
	end

	error(
		("%s\nexpected: %s\nactual: %s"):format(
			message or "values are not equal",
			vim.inspect(expected),
			vim.inspect(actual)
		),
		2
	)
end

function M.truthy(value, message)
	if value then
		return
	end

	error(message or "expected value to be truthy", 2)
end

return M
