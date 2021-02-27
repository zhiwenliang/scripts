#!/bin/bash

main() {
    for dir in $(ls -d */); do
        cd $dir
        echo "-------------$dir----------------"
        if [ -d ".git" ]; then
            git pull
        else
            echo 'not git directory'
            for dir1 in $(ls -d */); do
                cd $dir1
                echo "-------------$dir1----------------"
                echo "into $dir1"
                if [ -d ".git" ]; then
                    git pull
                fi
                cd ..
            done
        fi
        cd ..
    done
}

main
