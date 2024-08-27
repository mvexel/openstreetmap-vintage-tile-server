# OpenStreetMap Vintage Tile Server

![](https://i.imgur.com/9XW6ql4.png)

##[Demo server](https://osm.lol/)

**Please help support running costs of the demo server ($40/month, mostly storage cost)** Click the Patreon link on the right to learn more.

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

*With a default Docker installation on Linux, you will need to run the script as root. Never run random things from the internet as root. Don't trust me. Inspect the script and trust it.*

`./osm-vintage-tile-server.sh /path/to/history.osh.pbf 2008`

This example will take `/path/to/history.osh.pbf`, create a 2008-01-01 vintage planet, set up a tile server with that data, and expose it at port 8008. (The port will be 6000 + the year you choose.)

## Bonus: Side By Side HTML

![](https://i.imgur.com/rp7L5eA.png)

To see the tiles from your new vintage server side by side with the live OSM tiles, you can use the HTML + JS included in the `html/` subdirectory. Just change the URL in [this line](https://github.com/mvexel/openstreetmap-vintage-tile-server/blob/main/html/index.html#L43) to point to your own server and load `index.html` in your browser.

This uses the [leaflet-hash](https://github.com/mlevans/leaflet-hash) and [leaflet-side-by-side](https://github.com/digidem/leaflet-side-by-side) plugins, which are included. Leaflet itself is loaded from a CDN.

## Credits

* [osmium](https://osmcode.org/osmium-tool/) takes care of time-slicing the full history planet. It continues to blow my mind how fast this tool is and how much it can do.
* The actual heavy lifting is done by the [openstreetmap-tile-server Docker image](https://github.com/Overv/openstreetmap-tile-server).
