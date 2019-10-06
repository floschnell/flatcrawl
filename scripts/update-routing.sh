#!/bin/bash
profiles=( "car" "bicycle" "foot" )

# download region
if [[ ! -f "data/map.osm.pbf" ]]; then
  echo "download new map material ..."
  wget http://download.geofabrik.de/europe/germany/bayern-latest.osm.pbf
  mv bayern-latest.osm.pbf ./data/map.osm.pbf
fi

for profile in "${profiles[@]}"
do
  if [[ ! -f $profile.tar.gz ]]; then
    # run preprocessing for car
    current_dir=$(pwd)
    docker run -t -v $current_dir/data:/data osrm/osrm-backend:v5.22.0 osrm-extract -p /opt/$profile.lua /data/map.osm.pbf
    docker run -t -v $current_dir/data:/data osrm/osrm-backend:v5.22.0 osrm-partition /data/map.osrm
    docker run -t -v $current_dir/data:/data osrm/osrm-backend:v5.22.0 osrm-customize /data/map.osrm

    # zip relevant files
    mkdir $profile
    mv ./data/*osrm* ./$profile/
    tar -zcvf $profile.tar.gz ./$profile
    rm -rf ./$profile
  else
    echo "skipping $profile ..."
  fi
done

for profile in "${profiles[@]}"
do
  # copy files to server
  scp $profile.tar.gz root@floschnell.de:/opt/osm/

  # unpack files on server
  ssh root@floschnell.de "tar -zcvf $profile.tar.gz"
done