#!/bin/bash

echo 'This script will create a Docker image serving OSM tiles for a vintage of your choosing.'

# check if we have docker and osmium 
hash osmium 2>/dev/null || { echo >&2 "Please install osmium-tool before continuing."; exit 1; }
hash docker 2>/dev/null || { echo >&2 "Please install docker before continuing."; exit 1; }

# Get vintages to create
if [[ "$#" -ne 2 ]];
then 
    echo "Please run as osm-vintage-tile-server.sh path/to/history.osh.pbf YEAR"
    exit 1
else
    BASEDIR=$(cd `dirname $0` && pwd -P)
    OSM_FILE=$1

    # Check if file exists
    if ! [[ -f $OSM_FILE ]]; then
        echo 'File does not exist' >&2
        exit 1
    fi

    YEAR=$2
    CURRENT_YEAR=$(date +%Y)
    EPOCH_YEAR=2004
    PORT=$(($YEAR + 6000))

    # Check whether the second argument is a valid year (2004-2021)
    case $YEAR in
        ("" | *[!0-9]{4})
            echo 'Please provide a 4-digit YEAR' >&2
            exit 1
            ;;
        *)
            if [ $YEAR -le $EPOCH_YEAR ] || [ $YEAR -ge $CURRENT_YEAR ]; then
                echo "Please provide a 4-digit YEAR after ${EPOCH_YEAR} and before ${CURRENT_YEAR}" >&2
                exit 1
            fi
    esac

    echo "OK"
    echo "Slicing planet for Jan 1 ${YEAR}..."
    osmium time-filter --progress -o ${YEAR}.osm.pbf ${OSM_FILE} ${YEAR}-01-01T00:00:00Z 
    echo "Creating Docker volumes..."
    docker volume create openstreetmap-data-${YEAR}
    docker volume create openstreetmap-tiles-${YEAR}
    echo "Creating Docker container and importing ${YEAR} data. This will take minutes to hours..."
    docker run -v ${BASEDIR}/${YEAR}.osm.pbf:/data/region.osm.pbf -v openstreetmap-data-${YEAR}:/data/database/ -v openstreetmap-tiles-${YEAR}:/data/tiles/ --name osm-import-${YEAR} overv/openstreetmap-tile-server import >/dev/null 2>&1
    echo "Starting Container..."
    docker run -p ${PORT}:80 -v openstreetmap-data-${YEAR}:/data/database/ -v openstreetmap-tiles-${YEAR}:/data/tiles/ --name osm-vintage-tile-server-${YEAR} -d overv/openstreetmap-tile-server run
    echo "Done. Please visit http://localhost:${PORT} to enjoy your vintage tiles."
fi
