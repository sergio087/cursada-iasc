#!/bin/bash

cd `dirname $0` 

pids='';

# run foro
node foro-server.js iasc 127.0.0.1:8001 > ./logs/foro.log  2>&1 &
pids="${pids} $!"
sleep 1

# run docentes
for i in 1 2; do
  port=`expr 8100 + $i`
  node docente-server.js docente${i} 127.0.0.1:${port} 127.0.0.1:8001 > ./logs/docente${i}.log 2>&1 &
  pids="${pids} $!"
  sleep 2
done

# run alumnos
for i in 1 2; do
  port=`expr 8200 + $i`
  node alumno-server.js alumno${i} 127.0.0.1:${port} 127.0.0.1:8001 > ./logs/alumno${i}.log 2>&1 &
  pids="${pids} $!"
  sleep 2
done

echo "Press any key to kill $pids"

read

kill -9 $pids

exit 0
