#!/bin/bash


echo "#########################################"
echo "TEST of SCIDB's GEOTRANSFORM MACROS"
echo "#########################################"

#Add coords to TRMM
#ARRAY_NAME = "TRMM_AMZ_COMP"
#XSIZE = 0.25
#YSIZE = 0.25
#XORIGIN = -179.875
#YORIGIN = -49.875
#XCOORDATT = "Xcoord"
#YCOORDATT = "Ycoord"
#XINVERT = 1
#YINVERT = -1
#apply(ARRAY_NAME, XCOORDATT, XINVERT * (col_id * XSIZE + XORIGIN), YCOORDATT, YINVERT * (row_id * YSIZE + YORIGIN));



#Add coords to MODIS
#ARRAY_NAME = "MOD09Q1_SALESKA"
#XSIZE = 231.656358263889
#YSIZE = 231.656358263889
#XORIGIN = -20014993.5258209
#YORIGIN = -10007438.8488209
#XCOORDATT = "Xcoord"
#YCOORDATT = "Ycoord"
#XINVERT = 1
#YINVERT = -1
#apply(ARRAY_NAME, XCOORDATT, XINVERT * (col_id * XSIZE + XORIGIN), YCOORDATT, YINVERT * (row_id * YSIZE + YORIGIN));



#MACRO EXAMPLE save the following  distance.txt:
#distance(x1,y1,x2,y2) = sqrt(sq(x2 - x1) + sq(y2 - y1)) where
#{
#sq(x) = pow(x,2) -- the square of the scalar "x"
#}
#
#MACRO LOAD
#iquery -aq "load_module('/home/scidb/macros/distance.txt')"
#iquery -aq "list('macros')"
#MACRO TEST
#iquery -aq "store(build(<x:double>[i=0:9,10,0], i*50), Aun);"
#iquery -aq "store(apply(Aun, y, x * 3), A);"
#iquery -aq "store(build(<x:double> [i=0:9,10,0], random()%2000/2000.0), Bun);"
#iquery -aq "store(apply(Bun, y, x * 3), B);"
#iquery -aq "filter(project(apply(join(A,B), dist, distance(A.x, A.y, B.x,B.y)),dist),dist < 6)"
#iquery -aq "remove(Aun);"
#iquery -aq "remove(Bun);"
#iquery -aq "remove(A);"
#iquery -aq "remove(B);"


#echo "------------------------------"
#echo "Create array of transformation parameters..."
#echo "------------------------------"
#DROP ARRAY GEODEF; -- GEODEF stores the parameters for transforming col_id and row_id into coords
#CREATE ARRAY GEODEF <aname:string, key:string, value:string>[i=0:*,10,0];
#INSERT INTO GEODEF '[(TRMM_3B43_SALESKA, invertValuex, 1), (TRMM_3B43_SALESKA, invertValuey, -1), (TRMM_3B43_SALESKA, lengthx, 0.25), (TRMM_3B43_SALESKA, lengthy, 0.25), (TRMM_3B43_SALESKA, originx, -179.875), (TRMM_3B43_SALESKA, originy, -49.875)]';
#TODO: Find how to query and inject the these parameters into the function calls
#CREATE ARRAY SPATIALREFSYS - This array stores the 3 or 7 parameters for geocentric transformations - Use WGS84 as coomon ground for transformation, the parameters are available at http://www.globalmapper.com/helpv11/datum_list.htm
#+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs
#TODO: Alternatively, process the parameters from proj4 string using the -towgs84 parameter

echo "------------------------------"
echo "Loading the macro..."
echo "------------------------------"
iquery -aq "load_module('/home/scidb/macros/geoTransformation.txt')"
iquery -aq "list('macros')"


echo "------------------------------"
echo "TEST: add coords to TRMM array and back"
echo "Inspect first RES --  (0,-179.875,49.875), ( 100,-179.875,49.625), ( 100,-179.625,49.625), (150,-179.625,49.625)"
echo "Last RES must be all 0s"
echo "------------------------------"
iquery -naq "remove(GT);"
iquery -naq "remove(GT_coods);"
iquery -naq "remove(GT_coods_back);"
iquery -naq "remove(GT_coods_back_eval);"
iquery -naq "store(build(<val:double>[col_id=0:1,10,0, row_id=0:1,10,0], col_id*50 + row_id*100), GT);"
iquery -aq "store(apply(GT, Xcoord, id2coord(GT.col_id, 1, 0.25, -179.875), Ycoord, id2coord(GT.row_id, -1, 0.25, -49.875)), GT_coods);"
iquery -naq "store(apply(GT_coods, col_id_back, coord2id(Xcoord, 1, 0.25, -179.875), row_id_back, coord2id(Ycoord, -1, 0.25, -49.875)), GT_coods_back);"
iquery -aq "store(project(apply(GT_coods_back, RES_col_id, col_id - col_id_back, RES_row_id, row_id - row_id_back), RES_col_id, RES_row_id), GT_coods_back_eval);"




echo "------------------------------"
echo "TEST: PI, radians, decimal degrees"
echo "First col: 0, pi, pi, 2*pi"
echo "Second col: 0, ,0.0548311, ,0.0548311, ,0.109662"
echo "Last col: 0s"
echo "------------------------------"
iquery -naq "remove(GT);"
iquery -naq "remove(GT_dd_back);"
iquery -naq "store(build(<val:double>[col_id=0:1,10,0, row_id=0:1,10,0], col_id*PI() + row_id*PI()), GT);"
iquery -aq "store(apply(GT, dd, dd2rad(val), RES, val - rad2dd(dd2rad(val))), GT_dd_back);"




echo "------------------------------"
echo "TEST: add sinusoidal coords to MODIS array, then transform to spheric LONLAT and back"
echo "ncol_id and nrow_id are used as indexes."
echo "IF ncol_id=4800 AND row_id=4800 THEN Xcoord=-8895490 AND Ycoord=-1112070 THEN lonSphericDD=-81.2333 and latSphericDD=-10.001"
echo "IF ncol_id=4801 AND row_id=4801 THEN Xcoord=-8895260 AND Ycoord=-1112300 THEN lonSphericDD=-81.2317 and latSphericDD=-10.003"
echo "Last 2 columns must be very small or 0."
echo "------------------------------"
iquery -naq "remove(GT);"
iquery -naq "remove(GT_ids);"
iquery -naq "remove(GT_ids_coods);"
iquery -naq "remove(GT_ids_coods_latlon);"
iquery -naq "remove(GT_ids_coods_latlon_xyback);"
iquery -naq "remove(GT_ids_coods_latlon_xyback_idback);"
iquery -naq "store(build(<ncol_id:double>[col_id=0:1,10,0, row_id=0:1,10,0], 48000 + col_id), GT);"
iquery -naq "store(apply(GT, nrow_id, 48000 + row_id), GT_ids);"
iquery -naq "store(apply(GT_ids, Xcoord, id2coord(ncol_id, 1, 231.656358263889, -20014993.5258209), Ycoord, id2coord(nrow_id, -1, 231.656358263889, -10007438.8488209)), GT_ids_coods);"
iquery -naq "store(apply(GT_ids_coods, lonSphericDD, rad2dd(sinusoidal2sphericLON(Xcoord, sinusoidal2sphericLAT(Ycoord, 6371007.181), 6371007.181, 0)), latSphericDD, rad2dd(sinusoidal2sphericLAT(Ycoord, 6371007.181))), GT_ids_coods_latlon);"
iquery -naq "store(apply(GT_ids_coods_latlon, Xcoord_back, spheric2sinusoidalX(6371007.181, dd2rad(lonSphericDD), 0, dd2rad(latSphericDD)), Ycoord_back, spheric2sinusoidalY(6371007.181, dd2rad(latSphericDD))), GT_ids_coods_latlon_xyback);"
iquery -aq "store(apply(GT_ids_coods_latlon_xyback, Xcoord_diff, Xcoord_back - Xcoord, Ycoord_diff, Ycoord_back - Ycoord), GT_ids_coods_latlon_xyback_idback);"




echo "------------------------------"
echo "TEST: Spheric-Geocentric and back"
echo "Last 3 columns must be very small or 0."
echo "------------------------------"
iquery -naq "remove(GT);"
iquery -naq "remove(GT_ids);"
iquery -naq "remove(GT_ids_coods);"
iquery -naq "remove(GT_ids_coods_latlon);"
iquery -naq "remove(GT_ids_coods_latlon_geocentric);"
iquery -naq "remove(GT_ids_coods_latlon_geocentric_back);"
iquery -naq "remove(GT_ids_coods_latlon_geocentric_back_RES);"
iquery -naq "store(build(<ncol_id:double>[col_id=0:1,10,0, row_id=0:1,10,0], 48000 + col_id), GT);"
iquery -naq "store(apply(GT, nrow_id, 48000 + row_id), GT_ids);"
iquery -naq "store(apply(GT_ids, Xcoord, id2coord(ncol_id, 1, 231.656358263889, -20014993.5258209), Ycoord, id2coord(nrow_id, -1, 231.656358263889, -10007438.8488209)), GT_ids_coods);"
iquery -naq "store(apply(GT_ids_coods, lonSphericRAD, sinusoidal2sphericLON(Xcoord, sinusoidal2sphericLAT(Ycoord, 6371007.181), 6371007.181, 0), latSphericRAD, sinusoidal2sphericLAT(Ycoord, 6371007.181)), GT_ids_coods_latlon);"
iquery -naq "store(apply(GT_ids_coods_latlon, Xgeocen, spheric2geocentricX(6371007.181, lonSphericRAD, latSphericRAD), Ygeocen, spheric2geocentricY(6371007.181, lonSphericRAD, latSphericRAD), Zgeocen, spheric2geocentricZ(6371007.181, latSphericRAD)), GT_ids_coods_latlon_geocentric);"
iquery -naq "store(apply(GT_ids_coods_latlon_geocentric, radius, geocentric2sphericR(Xgeocen, Ygeocen, Zgeocen), latSphericRAD_back, geocentric2sphericLAT(Xgeocen, Ygeocen, Zgeocen), lonSphericRAD_back, geocentric2sphericLON(Xgeocen, Ygeocen)), GT_ids_coods_latlon_geocentric_back);"
iquery -aq "store(apply(GT_ids_coods_latlon_geocentric_back, lonDiff, lonSphericRAD - lonSphericRAD_back, latDiff, latSphericRAD - latSphericRAD_back, rDiff, 6371007.181 - radius), GT_ids_coods_latlon_geocentric_back_RES);"




echo "------------------------------"
echo "TEST: ellipsoidal to geocentric and back"
echo "Last 2 columns must be very small or 0."
echo "------------------------------"
#iquery -naq "remove(GT);"
#iquery -naq "remove(GT_coods);"
#iquery -naq "remove(GT_coods_geocentric);"
#iquery -naq "remove(GT_coods_geocentric_back);"
#iquery -naq "store(build(<val:double>[col_id=0:1,10,0, row_id=0:1,10,0], col_id*50 + row_id*100), GT);"
#iquery -naq "store(apply(GT, lonWGS84deg, id2coord(GT.col_id, 1, 0.25, -179.875), latWGS84deg, id2coord(GT.row_id, -1, 0.25, -49.875)), GT_coods);"
##iquery -naq "store(apply(GT, lonWGS84deg, id2coord(GT.col_id, 1, 0.25, -179.875), latWGS84deg, -1*id2coord(GT.row_id, -1, 0.25, -49.875)), GT_coods);"
##iquery -naq "store(apply(GT, lonWGS84deg, -1*id2coord(GT.col_id, 1, 0.25, -179.875), latWGS84deg, -1*id2coord(GT.row_id, -1, 0.25, -49.875)), GT_coods);"
##iquery -naq "store(apply(GT, lonWGS84deg, -1*id2coord(GT.col_id, 1, 0.25, -179.875), latWGS84deg, id2coord(GT.row_id, -1, 0.25, -49.875)), GT_coods);"
##iquery -naq "store(apply(GT, lonWGS84deg, -1*id2coord(GT.col_id, 1, 0.25, -179.875) - 90, latWGS84deg, id2coord(GT.row_id, -1, 0.25, -49.875)), GT_coods);"
##iquery -naq "store(apply(GT, lonWGS84deg, -1*id2coord(GT.col_id, 1, 0.25, -179.875) - 90, latWGS84deg, -1 * id2coord(GT.row_id, -1, 0.25, -49.875)), GT_coods);"
##iquery -naq "store(apply(GT, lonWGS84deg, -1*id2coord(GT.col_id, 1, 0.25, -179.875) - 180, latWGS84deg, -1 * id2coord(GT.row_id, -1, 0.25, -49.875)), GT_coods);"
#iquery -naq "store(apply(GT_coods, Xgeocen, ellipsoidal2geocentricX(6378137, 1/298.257223563, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 0), Ygeocen, ellipsoidal2geocentricY(6378137, 1/298.257223563, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 0), Zgeocen, ellipsoidal2geocentricZ(6378137, 1/298.257223563, dd2rad(latWGS84deg), 0)), GT_coods_geocentric);"
#iquery -aq "store(apply(GT_coods_geocentric, lonWGS84deg_back, rad2dd(geocentric2ellipsoidalLON(Xgeocen, Ygeocen)), latWGS84deg_back, rad2dd(geocentric2ellipsoidalLAT(6378137, 1/298.257223563, Xgeocen, Ygeocen, Zgeocen))), GT_coods_geocentric_back);"
iquery -naq "remove(GT_coods);"
iquery -naq "remove(GT_coods_geocentric);"
iquery -naq "remove(GT_coods_geocentric_back);"
iquery -naq "remove(GT_coods_geocentric_back_diff);"
iquery -naq "CREATE ARRAY GT_coods <lonWGS84deg:double, latWGS84deg:double>[col_id=0:2,10,0, row_id=0:1,10,0];"
iquery -nq "INSERT INTO GT_coods '[[(-179.875,49.875) (179.875,49.875)][(89.875,49.875) (-0.125,-49.875)][(0,0) (180,90)]]'"
iquery -naq "store(apply(GT_coods, Xgeocen, ellipsoidal2geocentricX(6378137, 1/298.257223563, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 0), Ygeocen, ellipsoidal2geocentricY(6378137, 1/298.257223563, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 0), Zgeocen, ellipsoidal2geocentricZ(6378137, 1/298.257223563, dd2rad(latWGS84deg), 0)), GT_coods_geocentric);"
iquery -naq "store(apply(GT_coods_geocentric, lonWGS84deg_back, rad2dd(geocentric2ellipsoidalLON(Xgeocen, Ygeocen)), latWGS84deg_back, rad2dd(geocentric2ellipsoidalLAT(6378137, 1/298.257223563, Xgeocen, Ygeocen, Zgeocen))), GT_coods_geocentric_back);"
iquery -aq "store(apply(GT_coods_geocentric_back, lonDIFF, lonWGS84deg - lonWGS84deg_back, latDIFF, latWGS84deg - latWGS84deg_back), GT_coods_geocentric_back_diff);"




#TODO: test geocentric3pTransformationXYZ




echo "------------------------------"
echo "TEST: geocentric 7 parameters transformation"
echo "Last 3 columns must be very small or 0. (given in meters)"
echo "------------------------------"
#Geocentric WGS72 to geoocentric WGS84
#Example taken fom http://ftp.stu.edu.tw/BSD/NetBSD/pkgsrc/distfiles/epsg-6.11/G7-2.pdf
#Page 84
#
#dX = 0.000 m
#dY = 0.000 m
#dZ = +4.5 m
#R_X = 0.000 sec
#R_Y = 0.000 sec
#R_Z = +0.554 sec = 0.000002685868 radians
#dS = +0.219 ppm 
#
#X_S = 3657660.66 m
#Y_S = 255768.55 m 
#Z_S = 5201382.11 m 
#
#X_T = 3657660.78 m
#Y_T = 255778.43 m
#Z_T = 5201387.75 m 

iquery -naq "remove(GT_coods);"
iquery -naq "remove(GT_coods_WGS84);"
iquery -naq "remove(GT_coods_WGS84_diff);"
iquery -naq "CREATE ARRAY GT_coods <xWGS72_GEOCEN:double, yWGS72_GEOCEN:double, zWGS72_GEOCEN:double>[col_id=0:0,10,0];"
iquery -nq "INSERT INTO GT_coods '[(3657660.66, 255768.55, 5201382.11)]'"
iquery -naq "store(apply(GT_coods, xWGS84_GEOCEN, geocentric7pTransformationX(xWGS72_GEOCEN, yWGS72_GEOCEN, zWGS72_GEOCEN, 0, 1 + 0.219/1000000, 0, 0.000002685868), yWGS84_GEOCEN, geocentric7pTransformationY(xWGS72_GEOCEN, yWGS72_GEOCEN, zWGS72_GEOCEN, 0, 1 + 0.219/1000000, 0, 0.000002685868), zWGS84_GEOCEN, geocentric7pTransformationZ(xWGS72_GEOCEN, yWGS72_GEOCEN, zWGS72_GEOCEN, 4.5, 1 + 0.219/1000000, 0, 0)), GT_coods_WGS84);"
iquery -w 12 -aq "store(apply(GT_coods_WGS84, xDiff, xWGS84_GEOCEN - 3657660.78, yDiff, yWGS84_GEOCEN - 255778.43, zDiff, zWGS84_GEOCEN - 5201387.75), GT_coods_WGS84_diff);"




echo "------------------------------"
echo "TEST: Abridge Molodensky"
echo "Last 3 columns must be very small or 0."
echo "------------------------------"
#Example taken fom http://ftp.stu.edu.tw/BSD/NetBSD/pkgsrc/distfiles/epsg-6.11/G7-2.pdf
#Page 88
#	SOURCE				TARGET
#	WGS84				ED50
#a	6378137				6378388
#f	0.0033528107		0.0033670034
#e2	0.00669438			-
#ro	6377103.1977606		-
#v	6392088.01709558	-
#
#WGS84 to ED50		
#deltaX	84.87	
#deltaY	96.49	
#deltaZ	116.95	
#deltaA	251	
#deltaF	0.00001419270225588640	
#
#RESULTS
#deltaPHI 	= 2.743"
#deltaLAMDA = 5.097"
#delta h  	= -44.909 mts
#lamda ED50 = 2.13096666666667
#phi ED50 	= 53.8101555555556
#h ED50  	= 28.091
iquery -naq "remove(GT_coods);"
iquery -naq "remove(GT_coods_am);"
iquery -naq "remove(GT_coods_am_diff);"
iquery -naq "CREATE ARRAY GT_coods <lonWGS84deg:double, latWGS84deg:double, hWGS84:double>[col_id=0:0,10,0];"
iquery -nq "INSERT INTO GT_coods '[(2.12955, 53.8093944444444, 73)]'"
iquery -naq "store(apply(GT_coods, lonED50deg, lonWGS84deg + amDeltaLamda(6378137, 0.0033528107, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 84.87, 96.49)/3600, latED50deg, latWGS84deg + amDeltaPhi(6378137, 0.0033528107, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 84.87, 96.49, 116.95, 251, 0.00001419270225588640)/3600, hED50, hWGS84 + amDeltaH(6378137, 0.0033528107, dd2rad(lonWGS84deg), dd2rad(latWGS84deg), 84.87, 96.49, 116.95, 251, 0.00001419270225588640)), GT_coods_am);"
iquery -w 12 -aq "store(apply(GT_coods_am, lonED50_diff, 2.13096666666667 - lonED50deg, latED50_diff, 53.8101555555556 - latED50deg, hED50_diff, 28.091 - hED50), GT_coods_am_diff);"





echo "------------------------------"
echo "TEST: From MODIS SINUSOIDAL to WGS84 using Abridge Molodensky"
echo "Last 3 columns must be very small or 0."
echo "------------------------------"
#	SOURCE				TARGET
#	SPHERIC				WGS84
#a	6371007.181			6378137				
#f	0					0.0033528107
#
#SPHERIC to WGS84
#deltaX	0
#deltaY	0
#deltaZ	0
#deltaA	7129.8190000001
#deltaF	0.0033528107
#
#UNKNOWN EXPECTED ANSWER

iquery -naq "remove(GT_coods);"
iquery -naq "remove(GT_coods_latlon);"
iquery -naq "remove(GT_coods_latlonRADDD);"
iquery -naq "remove(GT_coods_latlonRADDD_WGS84);"

iquery -naq "CREATE ARRAY GT_coods <xMODSIN:double, yMODSIN:double>[col_id=0:0,10,0];"
iquery -nq "INSERT INTO GT_coods '[(-8895490, 1111830)]'"
iquery -naq "store(apply(GT_coods, lonSphericRAD, sinusoidal2sphericLON(xMODSIN, sinusoidal2sphericLAT(yMODSIN, 6371007.181), 6371007.181, 0), latSphericRAD, sinusoidal2sphericLAT(yMODSIN, 6371007.181)), GT_coods_latlonRAD);"
iquery -naq "store(apply(GT_coods_latlonRAD, lonSphericDD, rad2dd(lonSphericRAD), latSphericDD, rad2dd(latSphericRAD)), GT_coods_latlonRADDD);"
iquery -w 12 -aq "store(apply( GT_coods_latlonRADDD, lonWGS84deg, lonSphericDD + amDeltaLamda(6371007.181, 0, lonSphericRAD, latSphericRAD, 0, 0)/3600, latWGS84deg, latSphericDD + amDeltaPhi(6371007.181, 0, lonSphericRAD, latSphericRAD, 0, 0, 0, 7129.8190000001, 0.0033528107)/3600, hWGS84, amDeltaH(6371007.181, 0, lonSphericRAD, latSphericRAD, 0, 0, 0, 7129.8190000001, 0.0033528107)), GT_coods_latlonRADDD_WGS84);"



# TODO: There are differences with 
#echo -8895490 1111830 | cs2cs +proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs +to +proj=longlat +ellps=WGS84 +datum=WGS84
#echo -81.2328102781 9.9989729617 | cs2cs +proj=longlat +a=6371007.181 +b=6371007.181 +no_defs +to +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs  
