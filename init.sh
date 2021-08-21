./pf.sh &

sleep 5

alias vtctlclient="vtctlclient -server=localhost:15999 -logtostderr"
alias mysql="mysql -h 127.0.0.1 -P 3306 -u user"

vtctlclient ApplySchema -sql="$(cat schemas/configuration-schema.sql)" configuration
vtctlclient ApplySchema -sql="$(cat schemas/usercontent-schema.sql)" usercontent

vtctlclient ApplyVSchema -vschema="$(cat schemas/configuration-vschema.json)" configuration
vtctlclient ApplyVSchema -vschema="$(cat schemas/initial-usercontent-vschema.json)" usercontent