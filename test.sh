#! /bin/bash

username="$1"
password="$2"

set -x

base_url='http://localhost:9000/irods-rest/0.9.5'
creds=$(echo -n ${username}:${password} | base64)
bearer_token=$(curl -X POST -s -H "authorization: Basic $creds" "${base_url}/auth")
curl_opts='-s'

#
# /collections
#

# Stat a collection.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/collections" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'lpath=/tempZone/home/kory' \
    $curl_opts | jq
# List the contents of a collection.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/collections" \
    --data-urlencode 'op=list' \
    --data-urlencode 'lpath=/tempZone/home/kory' \
    $curl_opts | jq

#
# /query
#

# List all data objects in the catalog.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/query" \
    --data-urlencode 'op=execute' \
    --data-urlencode 'query=select COLL_NAME, DATA_NAME' \
    ${curl_opts} | jq

#
# /resources
#

# Stat demoResc.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=demoResc' \
    ${curl_opts} | jq
# Create a replication resource.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=create' \
    --data-urlencode 'name=repl_resc' \
    --data-urlencode 'type=replication' \
    ${curl_opts} | jq
# Create two unixfilesystem resources.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=create' \
    --data-urlencode 'name=ufs0' \
    --data-urlencode 'type=unixfilesystem' \
    --data-urlencode "host=$(hostname)" \
    --data-urlencode 'vault-path=/tmp/ufs0' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=create' \
    --data-urlencode 'name=ufs1' \
    --data-urlencode 'type=unixfilesystem' \
    --data-urlencode "host=$(hostname)" \
    --data-urlencode 'vault-path=/tmp/ufs0' \
    ${curl_opts} | jq
# Stat the new resources.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=repl_resc' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=ufs0' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=ufs1' \
    ${curl_opts} | jq
# Make the unixfilesystem resources a child of the replication resource
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=add_child' \
    --data-urlencode 'parent-name=repl_resc' \
    --data-urlencode 'child-name=ufs0' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=add_child' \
    --data-urlencode 'parent-name=repl_resc' \
    --data-urlencode 'child-name=ufs1' \
    ${curl_opts} | jq
# Stat the unixfilesystem resources to show that they are a child of the
# replication resource.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=ufs0' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=ufs1' \
    ${curl_opts} | jq
# Remove the unixfilesystem resources from the replication resource.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=remove_child' \
    --data-urlencode 'parent-name=repl_resc' \
    --data-urlencode 'child-name=ufs0' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=remove_child' \
    --data-urlencode 'parent-name=repl_resc' \
    --data-urlencode 'child-name=ufs1' \
    ${curl_opts} | jq
# Stat the unixfilesystem resources to show they are no longer leaf nodes
# of the replication resource.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=ufs0' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=ufs1' \
    ${curl_opts} | jq
# Delete all resources created by this script.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=remove' \
    --data-urlencode 'name=ufs0' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=remove' \
    --data-urlencode 'name=ufs1' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=remove' \
    --data-urlencode 'name=repl_resc' \
    ${curl_opts} | jq
# Show that the resources no longer exist.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=repl_resc' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=ufs0' \
    ${curl_opts} | jq
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/resources" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=ufs1' \
    ${curl_opts} | jq

#
# /metadata
#

# This curl calls are broken at the moment due to POST requests sending data via the HTTP
# request body. The handler will need to be adjusted for this. If the request was changed
# to use -G and --data-urlencode (instead of -d), the request would work, but the input values
# would be exposed on the request URL.
curl -H "authorization: Bearer $bearer_token" "${base_url}/metadata" \
    -d 'op=atomic_execute' \
    -d \
    '{
        "entity_name": "/tempZone/home/kory",
        "entity_type": "collection",
        "operations": [
            {
                "operation": "add",
                "attribute": "source",
                "value": "irods-rest-beast",
                "units": "c++"
            }
        ]
    }' \
    ${curl_opts} | jq

# Notice the value for "entity_type" below.
# The iRODS server rejects "file" correct, however, the error message isn't
# good at all. It results in the following cryptic message: "std::map::at:  invalid key"
# The API plugin should mention the name of the property that caused the operation to fail.
# Obviously not great, but not urgent either. Still trying to decide if this is worth fixing
# in 4.2.12. Nothing's broken, it's just not convenient to read.
curl -H "authorization: Bearer $bearer_token" "${base_url}/metadata" \
    -d 'op=atomic_execute' \
    -d \
    '{
        "entity_name": "/tempZone/home/kory",
        "entity_type": "file",
        "operations": [
            {
                "operation": "add",
                "attribute": "source",
                "value": "irods-rest-beast",
                "units": "c++"
            }
        ]
    }' \
    ${curl_opts} | jq

#
# /rules
#

# List available rule engine plugin instances.
# We really need to include the type of the REP instance here and in irule -a.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/rules" \
    --data-urlencode 'op=list_rule_engines' \
    ${curl_opts} | jq
# Execute a rule against a specific REP.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/rules" \
    --data-urlencode 'op=execute' \
    --data-urlencode 'rep-instance=irods_rule_engine_plugin-irods_rule_language-instance' \
    --data-urlencode 'rule-text=writeLine("serverLog", "REST API!!!")' \
    ${curl_opts} | jq
# Schedule a delay rule.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/rules" \
    --data-urlencode 'op=execute' \
    --data-urlencode 'rep-instance=irods_rule_engine_plugin-irods_rule_language-instance' \
    --data-urlencode 'rule-text=delay("<EF>60</EF><INST_NAME>irods_rule_engine_plugin-irods_rule_language-instance</INST_NAME>") { writeLine("serverLog", "REST API!!!"); }' \
    ${curl_opts} | jq
# List all delay rules.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/rules" \
    --data-urlencode 'op=list_delay_rules' \
    ${curl_opts} | jq
iqdel -a

#
# /data-objects
#

# Create a new empty data object.
data_object='/tempZone/home/kory/http_file.txt'
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/data-objects" \
    --data-urlencode 'op=touch' \
    --data-urlencode "lpath=$data_object" \
    $curl_opts | jq
# Stat the new data object.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/data-objects" \
    --data-urlencode 'op=stat' \
    --data-urlencode "lpath=$data_object" \
    $curl_opts | jq
# Write some bytes to the data object.
echo here are those bytes | istream write "$data_object"
# Stat the data object again to show that the size was updated.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/data-objects" \
    --data-urlencode 'op=stat' \
    --data-urlencode "lpath=$data_object" \
    $curl_opts | jq
# Give rods permission to read the data object.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/data-objects" \
    --data-urlencode 'op=set-permission' \
    --data-urlencode "lpath=$data_object" \
    --data-urlencode 'entity-name=rods' \
    --data-urlencode 'permission=read_object' \
    $curl_opts | jq
# Read the contents of the data object.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/data-objects" \
    --data-urlencode 'op=read' \
    --data-urlencode "lpath=$data_object" \
    --data-urlencode 'count=1000' \
    $curl_opts | jq
# Permanently remove the new data object (no trash).
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/data-objects" \
    --data-urlencode 'op=remove' \
    --data-urlencode 'no-trash=1' \
    --data-urlencode "lpath=$data_object" \
    $curl_opts | jq
# Show that the data object was removed.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/data-objects" \
    --data-urlencode 'op=stat' \
    --data-urlencode "lpath=$data_object" \
    $curl_opts | jq

#
# /users-groups
#

# Stat a user.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/users-groups" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=kory' \
    $curl_opts | jq
# Stat a group.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/users-groups" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=public' \
    $curl_opts | jq
# Stat a non-existence entity.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/users-groups" \
    --data-urlencode 'op=stat' \
    --data-urlencode 'name=does_not_exist' \
    $curl_opts | jq
# List all users in the catalog.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/users-groups" \
    --data-urlencode 'op=users' \
    $curl_opts | jq
# List all groups in the catalog.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/users-groups" \
    --data-urlencode 'op=groups' \
    $curl_opts | jq
# Create a new group.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/users-groups" \
    --data-urlencode 'op=create_group' \
    --data-urlencode 'name=http_group' \
    $curl_opts | jq
# Add a user to the new group.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/users-groups" \
    --data-urlencode 'op=add_to_group' \
    --data-urlencode 'group=http_group' \
    --data-urlencode 'user=kory' \
    $curl_opts | jq
# Remove the new group.
curl -G -H "authorization: Bearer $bearer_token" "${base_url}/users-groups" \
    --data-urlencode 'op=remove_group' \
    --data-urlencode 'name=http_group' \
    $curl_opts | jq
