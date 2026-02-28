#!/usr/bin/env tclsh
####################################################################
# Network-In! - Tests unitaires
# Tests des fonctions de conversion de masques réseau
#   calcul_mask_dec2cidr : masque décimal pointé -> notation CIDR
#   calcul_mask_cidr2dec : notation CIDR -> masque décimal pointé
####################################################################

package require tcltest
namespace import ::tcltest::*

# Chargement des fonctions à tester
# traitement.tcl ne contient que des définitions de proc,
# il peut être sourcé sans effet de bord
set test_dir [file dirname [file normalize [info script]]]
source [file join $test_dir .. usr lib network-in traitement.tcl]


# ===========================================================================
# Tests calcul_mask_dec2cidr (décimal pointé -> CIDR)
# ===========================================================================

test dec2cidr-classe-c "255.255.255.0 -> 24" -body {
    calcul_mask_dec2cidr "255.255.255.0"
} -result 24

test dec2cidr-classe-b "255.255.0.0 -> 16" -body {
    calcul_mask_dec2cidr "255.255.0.0"
} -result 16

test dec2cidr-classe-a "255.0.0.0 -> 8" -body {
    calcul_mask_dec2cidr "255.0.0.0"
} -result 8

test dec2cidr-slash25 "255.255.255.128 -> 25" -body {
    calcul_mask_dec2cidr "255.255.255.128"
} -result 25

test dec2cidr-slash30 "255.255.255.252 -> 30" -body {
    calcul_mask_dec2cidr "255.255.255.252"
} -result 30

test dec2cidr-slash32 "255.255.255.255 -> 32" -body {
    calcul_mask_dec2cidr "255.255.255.255"
} -result 32

test dec2cidr-slash0 "0.0.0.0 -> 0" -body {
    calcul_mask_dec2cidr "0.0.0.0"
} -result 0

test dec2cidr-deja-cidr "Valeur déjà en CIDR renvoyée telle quelle" -body {
    calcul_mask_dec2cidr "24"
} -result 24


# ===========================================================================
# Tests calcul_mask_cidr2dec (CIDR -> décimal pointé)
# ===========================================================================

test cidr2dec-24 "24 -> 255.255.255.0" -body {
    calcul_mask_cidr2dec 24
} -result "255.255.255.0"

test cidr2dec-16 "16 -> 255.255.0.0" -body {
    calcul_mask_cidr2dec 16
} -result "255.255.0.0"

test cidr2dec-8 "8 -> 255.0.0.0" -body {
    calcul_mask_cidr2dec 8
} -result "255.0.0.0"

test cidr2dec-25 "25 -> 255.255.255.128" -body {
    calcul_mask_cidr2dec 25
} -result "255.255.255.128"

test cidr2dec-30 "30 -> 255.255.255.252" -body {
    calcul_mask_cidr2dec 30
} -result "255.255.255.252"

test cidr2dec-32 "32 -> 255.255.255.255" -body {
    calcul_mask_cidr2dec 32
} -result "255.255.255.255"

test cidr2dec-0 "0 -> 0.0.0.0" -body {
    calcul_mask_cidr2dec 0
} -result "0.0.0.0"

test cidr2dec-deja-decimal "Valeur déjà en décimal renvoyée telle quelle" -body {
    calcul_mask_cidr2dec "255.255.255.0"
} -result "255.255.255.0"


# ===========================================================================
# Tests aller-retour (round-trip)
# ===========================================================================

test roundtrip-24 "Aller-retour CIDR 24" -body {
    calcul_mask_dec2cidr [calcul_mask_cidr2dec 24]
} -result 24

test roundtrip-16 "Aller-retour CIDR 16" -body {
    calcul_mask_dec2cidr [calcul_mask_cidr2dec 16]
} -result 16

test roundtrip-25 "Aller-retour CIDR 25" -body {
    calcul_mask_dec2cidr [calcul_mask_cidr2dec 25]
} -result 25


# Résultats
cleanupTests
