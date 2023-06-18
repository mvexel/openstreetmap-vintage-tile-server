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

    # skip time-filter step if ${YEAR}.osm.pbf already exists
    if ! [[ -f ${YEAR}.osm.pbf ]]; then
        echo "Slicing planet for Jan 1 ${YEAR}..."
        osmium time-filter --progress -o ${YEAR}.osm.pbf ${OSM_FILE} ${YEAR}-01-01T00:00:00Z 
    else
        echo "Skipping time-filter step. ${YEAR}.osm.pbf already exists."
    fi
    
    # quietly check the integrity of the PBF file, and exit if it's not OK
    echo "Checking integrity of ${YEAR}.osm.pbf..."
    osmium fileinfo --no-progress ${YEAR}.osm.pbf >/dev/null 2>&1 || { echo >&2 "File integrity check failed. Please try again."; exit 1; } 
    
    # stop and delete any existing Docker containers
    if docker ps -a | grep -q osm-import-${YEAR}; then
        echo "Stopping and deleting Docker container osm-import-${YEAR}..."
        docker stop osm-import-${YEAR} >/dev/null 2>&1
        docker rm osm-import-${YEAR} >/dev/null 2>&1
    fi
    if docker ps -a | grep -q osm-vintage-tile-server-${YEAR}; then
        echo "Stopping and deleting Docker container osm-vintage-tile-server-${YEAR}..."
        docker stop osm-vintage-tile-server-${YEAR} >/dev/null 2>&1
        docker rm osm-vintage-tile-server-${YEAR} >/dev/null 2>&1
    fi
    
    # delete any existing tile server and import images
    if docker images | grep -q overv/openstreetmap-tile-server; then
        echo "Deleting Docker image overv/openstreetmap-tile-server..."
        docker rmi overv/openstreetmap-tile-server >/dev/null 2>&1
    fi
    if docker images | grep -q overv/openstreetmap-tile-server-import; then
        echo "Deleting Docker image overv/openstreetmap-tile-server-import..."
        docker rmi overv/openstreetmap-tile-server-import >/dev/null 2>&1
    fi

    # check if the docker volumes exist, if they do, ask the user if they want to delete them
    if docker volume ls | grep -q openstreetmap-data-${YEAR}; then
        echo "Docker volume openstreetmap-data-${YEAR} already exists."
        read -p "Do you want to delete it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo "Deleting Docker volume openstreetmap-data-${YEAR}..."
            docker volume rm openstreetmap-data-${YEAR}
        fi
    fi
    if docker volume ls | grep -q openstreetmap-tiles-${YEAR}; then
        echo "Docker volume openstreetmap-tiles-${YEAR} already exists."
        read -p "Do you want to delete it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo "Deleting Docker volume openstreetmap-tiles-${YEAR}..."
            docker volume rm openstreetmap-tiles-${YEAR}
        fi
    fi

    # build the Docker image
    echo "Creating Docker volumes..."
    docker volume create openstreetmap-data-${YEAR}
    docker volume create openstreetmap-tiles-${YEAR}
    
    # run the data import
    echo "Creating Docker container and importing ${YEAR} data. This will take minutes to hours..."
    docker run -v ${BASEDIR}/${YEAR}.osm.pbf:/data/region.osm.pbf -v openstreetmap-data-${YEAR}:/data/database/ -v openstreetmap-tiles-${YEAR}:/data/tiles/ --name osm-import-${YEAR} overv/openstreetmap-tile-server import >/dev/null 2>&1
    docker logs -f osm-import-${YEAR} >/dev/null 2>&1 &

    # start the tile server container
    echo "Starting Container..."
    docker run -p ${PORT}:80 -v openstreetmap-data-${YEAR}:/data/database/ -v openstreetmap-tiles-${YEAR}:/data/tiles/ --name osm-vintage-tile-server-${YEAR} -d overv/openstreetmap-tile-server run
    echo "Done. Please visit http://localhost:${PORT} to enjoy your vintage tiles."
fi
