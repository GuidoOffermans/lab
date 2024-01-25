.PHONY: tf-init tf-plan tf-apply tf-destroy

tf-init:
	docker-compose run -T --rm terraform init

tf-plan:
	docker-compose run -T --rm terraform plan

tf-apply:
	terraform apply

tf-destroy:
	terraform destroy
