terraform init: download all the required plugins and store it in .terraform
 [Your Code] ──> Reads provider block ──> Downloads Plugin (.exe/.bin) ──> Creates .terraform/

terraform validate: scan the files for any syntax error

terraform plan: or called Dry Run. this is the read only action. It compares the local code with state file (.tfstate) and send the api request to cloud provider to check the infra matching the state file. and build dependency graph. 

terraform plan -out=tfplan: is to store the dry run result into test or json files, which helps for automation, testing. 

terraform apply:  [Execution Plan] ──> HTTP POST/PUT/DELETE requests ──> Cloud Infrastructure ──> Update State File

terraform destroy: to purge the infra which is created by the configuration file