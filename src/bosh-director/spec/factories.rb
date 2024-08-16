require 'factory_bot'

FactoryBot.define do
  factory :deployment_plan_stemcell, class: Bosh::Director::DeploymentPlan::Stemcell do
    add_attribute(:alias) { 'default' }
    name { 'bosh-ubuntu-xenial-with-ruby-agent' }
    os { 'ubuntu-xenial' }
    version { '250.1' }

    initialize_with { new(self.alias, name, os, version) }
  end

  factory :deployment_plan_manual_network, class: Bosh::Director::DeploymentPlan::ManualNetwork do
    name { 'manual-network-name' }
    subnets { [] }
    logger { Logging::Logger.new('TestLogger') }
    managed { false }

    initialize_with { new(name, subnets, logger, managed) }
  end

  factory :deployment_plan_job_network, class: Bosh::Director::DeploymentPlan::JobNetwork do
    name { 'job-network-name' }
    static_ips { [] }
    default_for { [] }
    association :deployment_network, factory: :deployment_plan_manual_network, strategy: :build

    initialize_with { new(name, static_ips, default_for, deployment_network) }
  end

  factory :deployment_plan_instance_group, class: Bosh::Director::DeploymentPlan::InstanceGroup do
    name { 'instance-group-name' }
    logger { Logging::Logger.new('TestLogger') }
    canonical_name { 'instance-group-canonical-name' }
    lifecycle { 'service' }
    jobs { [] }
    persistent_disk_collection { Bosh::Director::DeploymentPlan::PersistentDiskCollection.new(logger) }
    env { Bosh::Director::DeploymentPlan::Env.new({}) }
    vm_type { nil }
    vm_resources { nil }
    vm_extensions { nil }
    update { Bosh::Director::DeploymentPlan::UpdateConfig.new(Bosh::Spec::Deployments.minimal_manifest['update']) }
    networks { [] }
    default_network { {} }
    availability_zones { [] }
    migrated_from { [] }
    state { nil }
    instance_states { {} }
    deployment_name { 'simple' }
    association :stemcell, factory: :deployment_plan_stemcell, strategy: :build

    initialize_with do
      new(
        name: name,
        canonical_name: canonical_name,
        lifecycle: lifecycle,
        jobs: jobs,
        stemcell: stemcell,
        logger: logger,
        persistent_disk_collection: persistent_disk_collection,
        env: env,
        vm_type: vm_type,
        vm_resources: vm_resources,
        vm_extensions: vm_extensions,
        update: update,
        networks: networks,
        default_network: default_network,
        availability_zones: availability_zones,
        migrated_from: migrated_from,
        state: state,
        instance_states: instance_states,
        deployment_name: deployment_name,
      )
    end
  end

  to_create { |instance| instance.save(raise_on_failure: true) }

  factory :models_compiled_package, class: Bosh::Director::Models::CompiledPackage do
    sequence(:build) { |i| "compiled-package-build-#{i}" }
    sequence(:blobstore_id) { |i| "compiled-package-blobstore-id-#{i}" }
    sequence(:sha1) { |i| "compiled-package-sha1-#{i}" }
    sequence(:stemcell_os) { |i| "compiled-package-stemcell-os-#{i}" }
    sequence(:stemcell_version) { |i| "compiled-package-stemcell-version-#{i}" }
    dependency_key { '[]' }
    association :package, factory: :models_package, strategy: :create
  end

  factory :models_deployment, class: Bosh::Director::Models::Deployment do
    sequence(:name) { |i| "deployment-#{i}" }
    sequence(:manifest) { |i| "deployment-manifest-#{i}" }
  end

  factory :models_deployment_property, class: Bosh::Director::Models::DeploymentProperty do
    sequence(:name) { |i| "deployment-property-#{i}" }
    sequence(:value) { |i| "deployment-property-value-#{i}" }
    association :deployment, factory: :models_deployment, strategy: :create
  end

  factory :models_director_attribute, class: Bosh::Director::Models::DirectorAttribute do
    name { 'uuid' }
    sequence(:value) { |i| "director-uuid-#{i}" }
  end

  factory :models_network, class: Bosh::Director::Models::Network do
    sequence(:name) { |i| "network-#{i}" }
    type { 'manual' }
    created_at { Time.now }
    orphaned { false }
    orphaned_at { nil }
  end

  factory :models_package, class: Bosh::Director::Models::Package do
    sequence(:name) { |i| "package-#{i}" }
    sequence(:version) { |i| "package-v#{i}" }
    sequence(:blobstore_id) { |i| "package-blobstore-id-#{i}" }
    sequence(:sha1) { |i| "package-sha1-#{i}" }
    dependency_set_json { '[]' }
    association :release, factory: :models_release, strategy: :create
  end

  factory :models_release, class: Bosh::Director::Models::Release do
    sequence(:name) { |i| "release-#{i}" }
  end

  factory :models_release_version, class: Bosh::Director::Models::ReleaseVersion do
    sequence(:version) { |i| "release-version-v#{i}" }
    association :release, factory: :models_release, strategy: :create
  end

  factory :models_stemcell, class: Bosh::Director::Models::Stemcell do
    sequence(:name) { |i| "stemcell-#{i}" }
    sequence(:version) { |i| "stemcell-v#{i}" }
    sequence(:cid) { |i| "stemcell-cid-#{i}" }
    sequence(:operating_system) { |i| "stemcell-operating-system-#{i}" }
  end

  factory :models_stemcell_upload, class: Bosh::Director::Models::StemcellUpload do
    sequence(:name) { |i| "stemcell-upload-#{i}" }
    sequence(:version) { |i| "stemcell-upload-v#{i}" }
  end

  factory :models_subnet, class: Bosh::Director::Models::Subnet do
    sequence(:name) { |i| "subnet-#{i}" }
    sequence(:cid) { |i| "subnet-cid-#{i}" }
    range { '192.168.10.0/24' }
    gateway { '192.168.10.1' }
    reserved { '[]' }
    cloud_properties { '{}' }
    cpi { '' }
    association :network, factory: :models_network, strategy: :create
  end

  factory :models_task, class: Bosh::Director::Models::Task do
    state { 'queued' }
    timestamp { Time.now }
    sequence(:type) { |i| "task-type-#{i}" }
    sequence(:description) { |i| "task-description-#{i}" }
    traits_for_enum(:state, ['queued', 'processing', 'done', 'cancelling'])
  end

  factory :models_team, class: Bosh::Director::Models::Team do
    sequence(:name) { |i| "team-#{i}" }
  end

  factory :models_variable_set, class: Bosh::Director::Models::VariableSet do
    writable { false }
    association :deployment, factory: :models_deployment, strategy: :create
  end

  factory :models_template, class: Bosh::Director::Models::Template do
    sequence(:name) { |i| "template-#{i}" }
    sequence(:version) { |i| "template-v#{i}" }
    sequence(:blobstore_id) { |i| "template-blobstore-id-#{i}" }
    sequence(:sha1) { |i| "template-sha1-#{i}" }
    sequence(:fingerprint) { |i| "template-fingerprint-#{i}" }
    package_names_json { '[]' }
    association :release, factory: :models_release, strategy: :create
  end
end
