az login
az account set --subscription "subscription-id-here"

az network application-gateway redirect-config create --name httpToHttps --gateway-name appgw1 --resource-group webtest-eastus --type Permanent --target-listener https-listener --include-path true --include-query-string true --verbose

az network application-gateway rule create --gateway-name appgw1 --name redirect-rule --resource-group webtest-eastus --http-listener http-listener --rule-type Basic --redirect-config httpToHttps --verbose