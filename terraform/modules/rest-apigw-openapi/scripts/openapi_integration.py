import sys
import getopt
import copy
import yaml
import json

http_methods = ["get", "head", "options", "trace", "post", "put", "patch", "delete", "x-amazon-apigateway-any-method"]

def generate_apigw_integration(path_uri, path_parameters, api_version, use_service_prefix):
    normalized_uri = path_uri.replace("proxy+", "proxy")

    base_integration_uri = "http://${stageVariables.CustomDomainName}"

    if use_service_prefix:
        base_integration_uri += "/${stageVariables.ServicePrefix}"

    if api_version != '':
        base_integration_uri += "/${stageVariables.ApiVersion}"

    request_integration = {
        "type":  "http_proxy",
        "httpMethod": "ANY",
        "passthroughBehavior": "when_no_match",
        "connectionId": "${stageVariables.VpcLinkId}",
        "connectionType": "VPC_LINK",
        "uri": f"{base_integration_uri}{normalized_uri}"
    }

    if len(path_parameters) > 0:
        path_integrations = dict()
        for param in path_parameters:
            path_integrations[f"integration.request.path.{param}"] = f"method.request.path.{param}"
        request_integration["requestParameters"] = path_integrations

    return request_integration

def integrate_path(path_uri, path_data, api_version, use_service_prefix):
    path_params = []

    # TODO: OpenAPI spec allows refs for parameters, but we don't support it at the moment
    if "parameters" in path_data:
        parameters = path_data["parameters"]
        path_params = [param.get("name") for param in parameters if param.get("in") == "path"]

    # TODO: OpenAPI spec allows refs for parameters, but we don't support it at the moment
    for method in path_data:
        if method not in http_methods: continue # ignore fields such as 'description'

        if "parameters" in path_data[method]:
            parameters = path_data[method]["parameters"]
            path_params = list(set(path_params + [param.get("name") for param in parameters if param.get("in") == "path"]))

        path_data[method]["x-amazon-apigateway-integration"] = generate_apigw_integration(path_uri, path_params, api_version, use_service_prefix)

    return path_data

def integrate_openapi(openapi, api_version, use_service_prefix):
    integrated_openapi = copy.deepcopy(openapi)

    for path in integrated_openapi["paths"]:
        integrated_openapi["paths"][path] = integrate_path(path, integrated_openapi["paths"][path], api_version, use_service_prefix)

    integrated_openapi["x-amazon-apigateway-binary-media-types"] = ["multipart/form-data"]

    return integrated_openapi

def maintenance_integration(maintenance_openapi_path):
    integrated_openapi = ''
    
    with open(maintenance_openapi_path, mode="r", encoding="utf-8") as f:
        integrated_openapi = yaml.load(f, Loader=yaml.FullLoader)  
    
    return integrated_openapi

def default_integration(input_file, type, api_version, use_service_prefix, swagger_file, openapi):
    with open(input_file, mode="r", encoding="utf-8") as f:
        openapi = yaml.load(f, Loader=yaml.FullLoader)

    integrated_openapi = integrate_openapi(openapi, api_version, use_service_prefix)

    #If we're creating the BFF APIGW, then:
    if type == "bff":
        #Add the prefix "/backend-for-frontend" to any path in the "paths object" of the BFF OpenAPI
        for path in list(integrated_openapi.get('paths', {}).keys()):
            edited_path = f'/backend-for-frontend{path}'
            integrated_openapi['paths'][edited_path] = integrated_openapi['paths'].pop(path)

    #If the path of the "Swagger additional path" file is available, then:
    if swagger_file != '':
        #Open the Swagger additional path file
        with open(swagger_file, mode="r", encoding="utf-8") as f:
            #Load the content of the Swagger additional path file into the swagger_additional_paths_content variable
            swagger_openapi = yaml.load(f, Loader=yaml.FullLoader)

            if type == "bff":
                #Add the prefix "/backend-for-frontend" to any path in the "paths object" of the Swagger OpenAPI
                for path in list(swagger_openapi.get('paths', {}).keys()):
                    edited_path = f'/backend-for-frontend{path}'
                    swagger_openapi['paths'][edited_path] = swagger_openapi['paths'].pop(path)

            #Copy the content of the paths object into the swagger_paths variable
            swagger_paths = copy.deepcopy(swagger_openapi.get("paths", {}))
            #Append the content of the swagger_paths to the bottom of the paths object into the integrated_openapi variable
            integrated_openapi['paths'].update(swagger_paths)
    
    return integrated_openapi


def main(argv):
    input_file = ''
    output_file = ''
    type = ''
    api_version = ''
    use_service_prefix = False
    swagger_file = ''
    maintenance_openapi_path = ''
    openapi = None
    integrated_openapi = None

    try:
        opts, args = getopt.getopt(argv, "hi:o:t:v:ps:m:", ["input=", "output=", "type=", "api-version=", "use-service-prefix", "swagger=", "maintenance-openapi="])
    except getopt.GetoptError:
        print('openapi_integration.py -i <input-file> [-o <output-file>] [-t <type>] [-v <api-version>] [-p] [-s <swagger-file>] [-m <maintenance-openapi>]')
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print('openapi_integration.py -i <input-file> [-o <output-file>] [-t <type>] [-v <api-version>] [-p] [-s <swagger-file>] [-m <maintenance-openapi>]')
            sys.exit()
        elif opt in ("-i", "--input"):
            input_file = arg
        elif opt in ("-o", "--output"):
            output_file = arg
        elif opt in ("-t", "--type"):
            type = arg
        elif opt in ("-v", "--api-version"):
            api_version = arg
        elif opt in ("-p", "--use-service-prefix"):
            use_service_prefix = True
        elif opt in ("-s", "--swagger"):
            swagger_file = arg
        elif opt in ("-m", "--maintenance-openapi"):
            maintenance_openapi_path = arg

    if input_file == '':
        print('openapi_integration.py -i <inputfile> [-o <outputfile>] [-t <type>] [-v <api-version>] [-p] [-s <swagger-file>] [-m <maintenance-openapi>]')
        sys.exit(2)

    if maintenance_openapi_path == '':
        integrated_openapi = default_integration(input_file, type, api_version, use_service_prefix, swagger_file, openapi)
    else:
        integrated_openapi = maintenance_integration(maintenance_openapi_path)

    if output_file != '':
        with open(output_file, mode="w", encoding="utf-8") as f:
            yaml.dump(integrated_openapi, f, sort_keys=False, encoding="utf-8")

    print(json.dumps({
        'integrated_openapi_yaml': yaml.dump(integrated_openapi)
    }))

if __name__ == "__main__":
    main(sys.argv[1:])
