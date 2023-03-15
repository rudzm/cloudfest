
create-cluster:
	gcloud beta container --project "$(project_id)" \
		clusters create "cloudfest" \
		--no-enable-basic-auth \
		--cluster-version "1.24.9-gke.3200" \
		--release-channel "None" \
		--machine-type "e2-medium" \
		--disk-type "pd-balanced" \
		--disk-size "100" \
		--metadata disable-legacy-endpoints=true \
		--num-nodes "3" \
		--enable-ip-alias \
		--network "projects/$(project_id)/global/networks/default" \
		--subnetwork "projects/$(project_id)/regions/us-central1/subnetworks/default" \
		--no-enable-intra-node-visibility \
		--default-max-pods-per-node "110" \
		--no-enable-master-authorized-networks \
		--addons ConfigConnector \
		--enable-autoupgrade \
		--enable-autorepair \
		--max-surge-upgrade 1 \
		--max-unavailable-upgrade 0 \
		--workload-pool "$(project_id).svc.id.goog" \
		--enable-shielded-nodes \
		--node-locations "us-central1-c" \
		--region us-central1

get-credentials:
	gcloud container clusters get-credentials cloudfest --region us-central1 --project $(project_id)

configure-sa:
	gcloud iam service-accounts create config-connector-sa
		gcloud projects add-iam-policy-binding $(project_id) \
		--member="serviceAccount:config-connector-sa@$(project_id).iam.gserviceaccount.com" \
		--role="roles/editor"
	gcloud iam service-accounts add-iam-policy-binding \
		config-connector-sa@$(project_id).iam.gserviceaccount.com \
		--member="serviceAccount:$(project_id).svc.id.goog[cnrm-system/cnrm-controller-manager]" \
		--role="roles/iam.workloadIdentityUser"

install-binary:

	echo ############### Install ArgoCD binary ################
	curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
	sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
	rm argocd-linux-amd64
install-argocd:
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

forward_argo:
	kubectl port-forward svc/argocd-server -n argocd 8080:443 1>/dev/null 2>/dev/null &