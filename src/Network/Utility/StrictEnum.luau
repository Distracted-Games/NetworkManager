--!strict

--[[
	This type function allows a custom StrictEnum table's type to be set using the associated EnumType.

	Example:
	```lua
	local StrictEnum = require(path.to.StrictEnum)

	export type EnumType =
		"This"
		| "That"
		| "TheOther"

	local ExampleEnum: StrictEnum.FromUnion<EnumType> = {
		This = "This",
		That = "That",
		TheOther = "TheOther",
	}
	
	return ExampleEnum
	```

	If the table is missing a value from the EnumType list, an error will be shown (in Studio only for now).
	in addition, the table itself will now carry the correct key-value types even if missing.
]]

export type function FromUnion(unionType)
	assert(unionType:is("union"), "StrictEnum.FromUnion<> expects a union of string literals")

	-- selene: allow(undefined_variable)
	local tbl = types.newtable()
	for _, component in unionType:components() do
		tbl:setreadproperty(component, component)
		tbl:setwriteproperty(component, component)
		tbl:setindexer(unionType, unionType)
	end
	return tbl
end

return nil
