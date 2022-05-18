# Run this script on a running dkube cluster to generate list of images used saved as ./images.txt

imgsfile=images.txt
tmpfile=tmp-images.txt
rm $tmpfile $imgsfile 2> /dev/null

# Get all running images to get a list of non-dkube images
dkube_namespaces=(
"cert-manager"
"dkube"
"dkube-infra"
"istio-system"
"knative-eventing"
"knative-serving"
"kubeflow"
"dkube-cicd"
"tekton-pipelines"
)
for namespace in ${dkube_namespaces[@]}; do
        kubectl get pods --namespace $namespace -o jsonpath="{.items[*].spec.containers[*].image}" |\
        tr -s '[[:space:]]' '\n' |\
        sort |\
        uniq >> $tmpfile
done

# Additional cluster images
echo "docker.io/kfserving/storage-initializer:v0.6.1
docker.io/library/bash:devel-alpine3.14
docker.io/bash:latest
gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/entrypoint:v0.24.1@sha256:b2133bcb5942dc9cc0ece08090924464aa60a2be80e8c53b8949312f5b60c37a
gcr.io/knative-releases/knative.dev/serving/cmd/queue@sha256:0b8e031170354950f3395876961452af1c62f7ab5161c9e71867392c11881962
gcr.io/distroless/base@sha256:aa4fd987555ea10e1a4ec8765da8158b5ffdfef1e72da512c7ede509bc9966c4
docker.io/kubeflowkatib/suggestion-hyperopt:v0.12.0
gcr.io/google-containers/busybox
gcr.io/ml-pipeline/argoexec:v3.1.6-patch-license-compliance
docker.io/chris060986/python-kube-client:latest" >> $tmpfile

# Parse d3api image tag to use for all dkube images
tag=$(cat $tmpfile| grep d3api | sed 's/^.*://') 

# Dkube images
echo "docker.io/ocdr/dkube-d3installer:$tag
docker.io/ocdr/dkube-d3dbmigrate:$tag
docker.io/ocdr/dkube-d3stashcontroller:$tag
docker.io/ocdr/dkube-d3downloader:$tag
docker.io/ocdr/dkube-d3studylauncher:$tag
docker.io/ocdr/dkube-d3ext:$tag
docker.io/ocdr/dkube-d3wait:$tag
docker.io/ocdr/dkube-d3watcher:$tag
docker.io/ocdr/dkube-d3auth:$tag
docker.io/ocdr/dkube-d3api:$tag
docker.io/ocdr/dkubepl:$tag
docker.io/ocdr/dkubeadm:$tag
docker.io/ocdr/admission-webhook-server:$tag
docker.io/ocdr/dkube-airgap-admission-webhook-server:$tag
docker.io/ocdr/dkube-uiserver:$tag
docker.io/ocdr/d3kubeflow-migrate:$tag
docker.io/ocdr/dkube-dfabproxy:$tag
docker.io/ocdr/dkube-d3storagexporter:$tag
docker.io/ocdr/dkube-slurm-plugin:$tag
docker.io/ocdr/dkube-slurm-peerjob:$tag
docker.io/ocdr/dkube-inf-watcher:$tag
docker.io/ocdr/dkube-docs:$tag
docker.io/ocdr/dkube-d3inf:$tag
docker.io/ocdr/d3-mlflowserver:$tag
docker.io/ocdr/d3-kfplapiserver:$tag
docker.io/ocdr/kfserving-controller:$tag
docker.io/ocdr/studyjob-metrics-collector:$tag
docker.io/ocdr/d3project_eval:latest
docker.io/ocdr/dkubegc:latest
docker.io/ocdr/file-metrics-collector:v0.11.0
docker.io/ocdr/dkube-tensorboard:v2.6.0" >> $tmpfile

# Datascience images
kubectl get cm dkube-platform-cfg -n dkube -o json | jq '.data."config.json"' -r >cm.json;
cat cm.json |grep -o -P '(?<="image":").*?(?=")' >> $tmpfile
rm cm.json
# Additional DS images
echo "docker.io/smizy/scikit-learn:0.23-alpine
docker.io/smizy/scikit-learn:latest" >> $tmpfile


# To clean image names
valid_registries=(docker.io gcr.io ghcr.io public.ecr.aws quay.io rancher)
while read -r image; do
	image=${image#"registry-server.dkube.io:443/"} 

	# Set slash as delimiter
	IFS='/'
	#Read the split words into an array based on slash delimiter
	read -a strarr <<< $image

	registry=${strarr[0]}
	if [[ "$registry" != "sha256" ]]; then
		if [[ ! ${valid_registries[*]} =~ "$registry" ]]; then
			echo "docker.io/$image" >> $imgsfile
		else
			echo "$image" >> $imgsfile
		fi
	fi
done < $tmpfile

# Sort and remove repetitions
cat $imgsfile | sort | uniq > $tmpfile
rm $imgsfile
grep 'datascience' $tmpfile > $tag-ds.txt
sed -i '/datascience/d' $tmpfile
mv $tmpfile $tag-non-ds.txt
echo "Generated list of images in $tag-ds.txt and $tag-non-ds.txt!"
