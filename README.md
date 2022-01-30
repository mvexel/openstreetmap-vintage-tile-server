# OpenStreetMap Vintage Tile Server

![](https://i.imgur.com/9XW6ql4.png)

Ever long for the good old days when OSM was formless and void?

Now you can with a one-liner!

Well, almost:

## Prerequisites

This script has only been tested on a Linux (Ubuntu 21.10) machine.

You need [docker](https://docs.docker.com/engine/install/ubuntu/) and [osmium](https://osmcode.org/osmium-tool/manual.html) installed.

You need an OSM full history planet. You can obtain this from various [OSM planet mirrors](https://wiki.openstreetmap.org/wiki/Planet.osm#Planet.osm_mirrors), or for smaller regions (recommended!) from [Geofabrik](https://download.geofabrik.de/).

## Usage

Call the script with two arguments:
1. The full path to your history PBF
2. The 4-digit year you want tiles for

`./osm-vintage-tile-server.sh /path/to/history.osh.pbf 2008`

This example will take `/path/to/history.osh.pbf`, create a 2008-01-01 vintage planet, set up a tile server with that data, and expose it at port 8008. (The port will be 6000 + the year you choose.)

## Credits

* [osmium](https://osmcode.org/osmium-tool/) takes care of time-slicing the full history planet. It continues to blow my mind how fast this tool is and how much it can do.
* The actual heavy lifting is done by the [openstreetmap-tile-server Docker image](https://github.com/Overv/openstreetmap-tile-server).
