--[[
	Specifies the names of the RemoteEvent and RemoteFunction folders used by
    `createRemotesFolders` and `waitForAllRemotesAsync`.
]]

local StrictEnum = require("./Utility/StrictEnum")

export type EnumType = "RemoteEvents" | "RemoteFunctions"

local RemoteFolderName: StrictEnum.FromUnion<EnumType> = {
	RemoteEvents = "RemoteEvents",
	RemoteFunctions = "RemoteFunctions",
}

return RemoteFolderName
