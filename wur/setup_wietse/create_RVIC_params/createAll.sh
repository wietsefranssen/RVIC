#!/bin/bash
./create_vic_params.sh
./update_domainFileForForcing.sh
sleep 2
./create_rvic_params.sh
