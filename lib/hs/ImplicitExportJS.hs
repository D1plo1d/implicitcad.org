import System.Environment (getArgs)
import System.IO (openFile, IOMode (ReadMode), hGetContents, hClose)
import Graphics.Implicit (runOpenscad, writeSVG, writeSTL, writeOBJ)
import Graphics.Implicit.Definitions
import Graphics.Implicit.ExtOpenScad (OpenscadObj (ONum))
import qualified Data.Map as Map
import Graphics.Implicit.Export (writeObject)


writeJS res = writeObject res js

-- A formatter that turns a normed triangle mesh into javascript for implicitcad.org to import
js :: NormedTriangleMesh -> String
js normedtriangles = text
	where
		-- some dense JS. Let's make helper functions so that we don't repeat code each line
		header = 
			"var Shape = function(){\n"
			++  "var s = this;\n"
			++  "THREE.Geometry.call(this);\n"
			++  "function vec(x,y,z){return new THREE.Vector3(x,y,z);}\n"
			++  "function v(x,y,z){s.vertices.push(new THREE.Vertex(vec(x,y,z)));}\n"
			++  "function f(a,b,c,nax,nay,naz,nbx,nby,nbz,ncx,ncy,ncz){"
			++    "s.faces.push(new THREE.Face3(a,b,c,["
			++               "vec(nax,nay,naz),vec(nbx,nby,nbz),vec(ncx,ncy,ncz)"
			++    "]));"
			++  "}\n"
		footer =
			"}\n"
			++ "Shape.prototype = new THREE.Geometry();\n"
			++ "Shape.prototype.constructor = Shape;\n"
		-- A vertex line; v (0.0, 0.0, 1.0) = "v(0.0,0.0,1.0);\n"
		v :: ℝ3 -> String
		v (x,y,z) = "v("  ++ show x ++ "," ++ show y ++ "," ++ show z ++ ");\n"
		-- A face line
		f :: Int -> Int -> Int -> ℝ3 -> ℝ3 -> ℝ3 -> String
		f posa posb posc na@(nax, nay, naz) nb@(nbx, nby, nbz) nc@(ncx, ncy, ncz) = 
			"f("   ++ show posa ++ "," ++ show posb ++ "," ++ show posc 
			++ "," ++ show nax  ++ "," ++ show nay  ++ "," ++ show naz 
			++ "," ++ show nbx  ++ "," ++ show nby  ++ "," ++ show nbz 
			++ "," ++ show ncx  ++ "," ++ show ncy  ++ "," ++ show ncz ++ ");\n"
		verts = do
			-- extract the vertices for each triangle
			-- recall that a normed triangle is of the form ((vert, norm), ...)
			((a,_),(b,_),(c,_)) <- normedtriangles
			-- The vertices from each triangle take up 3 position in the resulting list
			[a,b,c]
		vertcode = concat $ map v verts
		facecode = concat $ do
			(n, normedTriangle) <- zip [0, 3 ..] normedtriangles
			let
				(posa, posb, posc) = (n, n+1, n+2)
				((_, na), (_, nb), (_, nc)) = normedTriangle
			return $ f posa posb posc na nb nc
		text = header ++ vertcode ++ facecode ++ footer





-- | Give an openscad object to run and the basename of 
--   the target to write to... write an object!
executeAndExportSpecifiedTargetType :: String -> String -> IO ()
executeAndExportSpecifiedTargetType content targetname = case runOpenscad content of
	Left err -> putStrLn $ show $ err
	Right openscadProgram -> do 
		s@(vars, obj2s, obj3s) <- openscadProgram 
		let
			res = case Map.lookup "$res" vars of 
				Nothing -> 1
				Just (ONum n) -> n
				Just (_) -> 1
		case s of 
			(_, _, x:xs)  -> do
				putStrLn $ "Rendering 3D object to " ++ targetname
				writeJS res targetname x

		

main :: IO()
main = do
	args <- getArgs
	case length args of
		2 -> do
			f <- openFile (args !! 0) ReadMode
			content <- hGetContents f 
			executeAndExportSpecifiedTargetType content (args !! 1)
			hClose f
		_ -> putStrLn $ 
			"syntax: extopenscad inputfile.escad outputfile.js\n"
			++ "eg. extopenscad input.escad out.js"

