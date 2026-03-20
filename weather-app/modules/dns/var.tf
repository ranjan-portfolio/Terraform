variable "hosted_zone"{
    description = "hosted zone name"
    type=string
}

variable "weatherapp_record"{
    description = "dns url of your weather app,this creates a CNAME record"
    type=string
}

variable "weatherapp_ttl"{
    description = "TTL of the weatherapp record"
    type=number
}

variable "weatherapp_value"{
    description = "Value where the record will point to"
    type=list(string)
}