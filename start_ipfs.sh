set -e
repo=/data/ipfs
webui_cdi1_latest="bafybeiflkjt66aetfgcrgvv75izymd5kc47g6luepqmfq6zsf5w6ueth6y"
webui_cdi1="bafybeid26vjplsejg7t3nrh7mxmiaaxriebbm4xxrxxdunlk7o337m5sqq"

ipfs version

if [ -e "$repo/config" ]; then
  echo "Found IPFS fs-repo at $repo"
else
  case "$IPFS_PROFILE" in
    "") INIT_ARGS="" ;;
    *) INIT_ARGS="--profile=$IPFS_PROFILE" ;;
  esac
  ipfs init $INIT_ARGS
  ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
  ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
  ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
  ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST"]'
  
  echo "starting default public daemon"
  nohup ipfs daemon >/dev/null 2>&1 &

  echo "add webui packages"
  cd /tmp
  curl https://ipfs.io/api/v0/get/$webui_cdi1_latest | tar -xf -
  ipfs add --cid-version 1 -r $webui_cdi1_latest
  
  curl https://ipfs.io/api/v0/get/$webui_cdi1 | tar xf -
  ipfs add --cid-version 1 -r $webui_cdi1  

  echo "kill daemon"
  killall ipfs

  echo "set private swarm"
  ipfs bootstrap rm --all
  ipfs bootstrap add /ip4/$(hostname -i)/tcp/4001/ipfs/$(ipfs config show | grep "PeerID" |  sed 's/^.*: "\(.*\)"$/\1/')

  # ----------------------------------------

  # Set up the swarm key, if provided
  IPFS_SWARM_KEY_FILE="$repo/swarm.key"
  IPFS_SWARM_KEY_PERM=0400

  # Create a swarm key from a given environment variable
  if [ ! -z "$IPFS_SWARM_KEY" ] ; then
    echo "Copying swarm key from variable..."
    echo -e "$IPFS_SWARM_KEY" >"$IPFS_SWARM_KEY_FILE" || exit 1
    chmod $IPFS_SWARM_KEY_PERM "$IPFS_SWARM_KEY_FILE"
  fi

  # Unset the swarm key variable
  unset IPFS_SWARM_KEY

  if [ -f "$IPFS_SWARM_KEY_FILE" ] ; then
    echo "Copying swarm key from file..."
    install -m $IPFS_SWARM_KEY_PERM "$IPFS_SWARM_KEY_FILE" "$IPFS_SWARM_KEY_FILE" || exit 1
  else
    echo -e "/key/swarm/psk/1.0.0/\n/base16/\n`tr -dc 'a-f0-9' < /dev/urandom | head -c64`" > $IPFS_SWARM_KEY_FILE
  fi

  # Unset the swarm key file variable
  unset IPFS_SWARM_KEY_FILE

fi

# force private mode, without a swarm key the dameon won't start
export LIBP2P_FORCE_PNET=1
ipfs daemon --unrestricted-api --writable
