class HTTPMethods : System.Management.Automation.IValidateSetValuesGenerator {

    [String[]] GetValidValues() {
        return [System.Net.Http.HttpMethod].GetProperties().Name
    }

}