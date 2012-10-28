for example in `cat implicit-cad-examples.txt`
do 
  echo $example
  extopenscad implicit-cad-examples/$example.escad ../app/assets/images/examples-$example.png
done
