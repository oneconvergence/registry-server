registry_server_ip=$1

# Create default projects
echo Creating default projects...
projects=("docker.io" "gcr.io" "ghcr.io" "public.ecr.aws" "quay.io" "rancher")
user="admin"
pass="bitnami"
for project in ${projects[@]}; do
	curl -XPOST -u "$user:$pass" "https://$registry_server_ip/api/v2.0/projects" \
	  -H 'accept: application/json, text/plain, */*' \
	  -H 'content-type: application/json' \
	  --data-raw "{\"project_name\":\"$project\",\"metadata\":{\"public\":\"true\"},\"storage_limit\":-1,\"registry_id\":null}" \
	  --compressed \
	  --insecure
done
echo Done creating default projects.
