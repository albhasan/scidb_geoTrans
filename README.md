scidb_geoTrans
==============

SciDB's macro for transforming among geographic coordinates

<h3>Files:</h3>
<ul>
	
	<li><code>LICENSE</code> - License file.</li>
	<li><code>README.md</code> - This file.</li>
	<li><code>geoTransformation.txt</code> - Text file with the macro's source code.</li>
	<li><code>geoTransformation_test.sh</code> - Test batch script.</li>
</ul>


<h3>Prerequisites:</h3>
<ul>
	<li>Internet access.</li>
	<li>A running instance of SciDB.</li>
</ul>



<h3>Instructions:</h3>
<ol>
	<li>Clone the project and CD to the project's  folder: <code>git clone http://github.com/albhasan/scidb_geoTrans.git</code></li>
	<li>Start the iquery client <code>iquery</code></li>
	<li>Create an array: <code>CREATE ARRAY GT_coods <lonWGS84deg:double, latWGS84deg:double, hWGS84:double>[col_id=0:0,10,0];</code></li>
	<li>Populate the array. These are WGS coords: <code>INSERT INTO GT_coods '[(2.12955, 53.8093944444444, 73)]';</code></li>
	<li>Run the transformation from WGS84 to ED50: <code>store(apply(GT_coods, lonED50deg, lonWGS84deg + amDeltaLamda(6378137, 0.0033528107, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 84.87, 96.49)/3600, latED50deg, latWGS84deg + amDeltaPhi(6378137, 0.0033528107, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 84.87, 96.49, 116.95, 251, 0.00001419270225588640)/3600, hED50, hWGS84 + amDeltaH(6378137, 0.0033528107, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 84.87, 96.49, 116.95, 251, 0.00001419270225588640)), GT_coods_am);</code></li>
</ol> 

The macro contains functions for the transformations:
<ul>
	<li>Transform dimmension' ids to coordinates.</li>
	<li>Transform spherical to sinusoidal (e.g MODIS) coordinates and back .</li>
	<li>Transform spherical to geocentric coordinates and back.</li>
	<li>Transform ellipsoidal to geocentric coordinates and back.</li>
	<li>Transform geocentric to geocentric coordinates using 3 or 7 parameters.</li>
	<li>Transform between geographic coordinate reference systems using the Abridged Molodensky formulae.</li>
</ul>
