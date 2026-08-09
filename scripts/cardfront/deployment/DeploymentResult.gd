extends RefCounted
class_name DeploymentResult

const SOURCE_NONE: String = ""
const SOURCE_CORE: String = "core"
const SOURCE_SUPPORT: String = "support"

var allowed: bool = false
var reason: String = ""
var region_id: int = -1
var owner_percent: int = 0
var resolved_support_id: String = ""
var source_kind: String = SOURCE_NONE
var debug_explanation: String = ""
