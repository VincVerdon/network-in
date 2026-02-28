#!/usr/bin/env tclsh
####################################################################
# Network-In! - Suite de tests unitaires
# Lanceur principal : exécute tous les fichiers test_*.tcl
####################################################################

package require tcltest
namespace import ::tcltest::*

# Répertoire contenant les tests
configure -testdir [file dirname [file normalize [info script]]]

# Exécution de tous les fichiers de test
runAllTests
