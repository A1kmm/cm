!> \file
!> $Id: opencmisstest.f90 20 2007-05-28 20:22:52Z cpb $
!> \author Chris Bradley
!> \brief This is a simple program to illustrate OpenCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is openCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> Main program
PROGRAM OPENCMISSTEST

  USE BASE_ROUTINES
  USE BASIS_ROUTINES
  USE CMISS
  USE CMISS_MPI
  USE COMP_ENVIRONMENT
  USE CONSTANTS
  USE COORDINATE_ROUTINES
  USE DISTRIBUTED_MATRIX_VECTOR
  USE FIELD_ROUTINES
  USE FIELD_IO_ROUTINES
  USE INPUT_OUTPUT
  USE ISO_VARYING_STRING
  USE KINDS
  USE LISTS
  USE MESH_ROUTINES
  USE MPI
  USE PROBLEM_ROUTINES
  USE REGION_ROUTINES
  USE TIMER
  USE TYPES

#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Test program parameters

  REAL(DP), PARAMETER :: HEIGHT=1.0_DP
  REAL(DP), PARAMETER :: WIDTH=2.0_DP
  
  !Program types

  
  !Program variables

  INTEGER(INTG) :: NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS
  INTEGER(INTG) :: NUMBER_OF_DOMAINS
  
  INTEGER(INTG) :: NUMBER_COMPUTATIONAL_NODES
  INTEGER(INTG) :: MY_COMPUTATIONAL_NODE_NUMBER
  INTEGER(INTG) :: MPI_IERROR
  
  TYPE(BASIS_TYPE), POINTER :: BASIS,BASIS2
  TYPE(COORDINATE_SYSTEM_TYPE), POINTER :: COORDINATE_SYSTEM
  !TYPE(MESH_ELEMENTS_TYPE), POINTER :: ELEMENTS
  TYPE(MESH_TYPE), POINTER :: MESH
  TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
  !TYPE(DOMAIN_TYPE), POINTER :: DOMAIN
  TYPE(FIELD_TYPE), POINTER :: GEOMETRIC_FIELD
  !TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
  !TYPE(FIELD_TYPE), POINTER :: MATERIAL_FIELD
  !TYPE(NODES_TYPE), POINTER :: NODES
  TYPE(PROBLEM_TYPE), POINTER :: PROBLEM
  !TYPE(QUADRATURE_SCHEME_TYPE), POINTER :: SCHEME
  TYPE(REGION_TYPE), POINTER :: REGION
  !TYPE(NODAL_INFO_SET_FOR_IO), POINTER :: PROCESS_NODAL_INFO_SET
  LOGICAL :: IMPORT_FIELD

  REAL(SP) :: START_USER_TIME(1),STOP_USER_TIME(1),START_SYSTEM_TIME(1),STOP_SYSTEM_TIME(1)
  !REAL(SP) :: UPDATE_START_USER_TIME(1),UPDATE_STOP_USER_TIME(1), UPDATE_START_SYSTEM_TIME(1),UPDATE_STOP_SYSTEM_TIME(1)

#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif
  
  !Generic CMISS variables
  
  INTEGER(INTG) :: ERR
  TYPE(VARYING_STRING) :: ERROR

  INTEGER(INTG) :: DIAG_LEVEL_LIST(5)
  CHARACTER(LEN=MAXSTRLEN) :: DIAG_ROUTINE_LIST(1),TIMING_ROUTINE_LIST(1)
  
#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

  !Intialise cmiss
  CALL CMISS_INITIALISE(ERR,ERROR,*999)
  
  !!Initialise the base routines
  !CALL BASE_ROUTINES_INITIALISE(ERR,ERROR,*999)

  !Set all diganostic levels on for testing
  DIAG_LEVEL_LIST(1)=1
  DIAG_LEVEL_LIST(2)=2
  DIAG_LEVEL_LIST(3)=3
  DIAG_LEVEL_LIST(4)=4
  DIAG_LEVEL_LIST(5)=5
  DIAG_ROUTINE_LIST(1)="PROBLEM_GLOBAL_MATRIX_STRUCTURE_CALCULATE"
  !DIAG_ROUTINE_LIST(1)="NODES_CREATE_FINISH"
  !DIAG_ROUTINE_LIST(1)="FIELD_GEOMETRIC_PARAMETERS_LINE_LENGTHS_CALCULATE"
  !DIAG_ROUTINE_LIST(1)="BASIS_CREATE_FINISH"
  !DIAG_ROUTINE_LIST(2)="GAUSS_SIMPLEX"
  !DIAG_ROUTINE_LIST(3)="DOMAIN_TOPOLOGY_LINES_CALCULATE"
  !DIAG_ROUTINE_LIST(4)="DOMAIN_TOPOLOGY_INITIALISE_FROM_MESH"
  !DIAG_ROUTINE_LIST(1)="DOMAIN_MAPPINGS_ELEMENTS_CALCULATE"
  !DIAG_ROUTINE_LIST(2)="DOMAIN_MAPPINGS_NODES_DOFS_CALCULATE"
  !DIAG_ROUTINE_LIST(1)="DOMAIN_TOPOLOGY_LINES_CALCULATE"
  !DIAG_ROUTINE_LIST(2)="DISTRIBUTED_VECTOR_UPDATE_START"
  !DIAG_ROUTINE_LIST(3)="DISTRIBUTED_VECTOR_UPDATE_FINISH"
  !DIAG_ROUTINE_LIST(1)="CALCULATE_MESH_DECOMPOSITION"
  !DIAG_ROUTINE_LIST(2)="CALCULATE_LOCAL_ELEMENTS_SURROUNDING_NODES"
  !DIAG_ROUTINE_LIST(3)="CALCULATE_ADJACENT_LOCAL_ELEMENTS"
  !DIAG_ROUTINE_LIST(1)="FINISH_CREATE_NODES"
  !DIAG_ROUTINE_LIST(2)="FINISH_CREATE_MESH_ELEMENTS"
  !DIAG_ROUTINE_LIST(3)="CALCULATE_MESH_NODES"
  !DIAG_ROUTINE_LIST(5)="FINISH_CREATE_DOMAIN_DECOMPOSITION"
  !DIAG_ROUTINE_LIST(6)="FINISH_CREATE_FIELD"
  !CALL DIAGNOSTICS_SET_ON(ALL_DIAG_TYPE,DIAG_LEVEL_LIST,"OpenCMISSTest",DIAG_ROUTINE_LIST,ERR,ERROR,*999)
  CALL DIAGNOSTICS_SET_ON(IN_DIAG_TYPE,DIAG_LEVEL_LIST,"",DIAG_ROUTINE_LIST,ERR,ERROR,*999)

  TIMING_ROUTINE_LIST(1)="PROBLEM_FINITE_ELEMENT_CALCULATE"
  !TIMING_ROUTINE_LIST(2)="DECOMPOSITION_ELEMENT_DOMAIN_CALCULATE"
  !TIMING_ROUTINE_LIST(3)="MESH_CREATE_REGULAR"
  CALL TIMING_SET_ON(IN_TIMING_TYPE,.TRUE.,"",TIMING_ROUTINE_LIST,ERR,ERROR,*999)
  
  !Calculate the start times
  CALL CPU_TIMER(USER_CPU,START_USER_TIME,ERR,ERROR,*999)
  CALL CPU_TIMER(SYSTEM_CPU,START_SYSTEM_TIME,ERR,ERROR,*999)
  
  !!Intialise the computational environment
  !CALL COMPUTATIONAL_ENVIRONMENT_INITIALISE(ERR,ERROR,*999)
  
  !Get the number of computational nodes
  NUMBER_COMPUTATIONAL_NODES=COMPUTATIONAL_NODES_NUMBER_GET(ERR,ERROR)
  IF(ERR/=0) GOTO 999
  !Get my computational node number
  MY_COMPUTATIONAL_NODE_NUMBER=COMPUTATIONAL_NODE_NUMBER_GET(ERR,ERROR)
  IF(ERR/=0) GOTO 999
  
  !Read in the number of elements in the X & Y directions, and the number of partitions on the master node (number 0)
  IF(MY_COMPUTATIONAL_NODE_NUMBER==0) THEN
    WRITE(*,'("Enter the number of elements in the X direction :")')
    READ(*,*) NUMBER_GLOBAL_X_ELEMENTS
    WRITE(*,'("Enter the number of elements in the Y direction :")')
    READ(*,*) NUMBER_GLOBAL_Y_ELEMENTS
    WRITE(*,'("Enter the number of domains :")')
    READ(*,*) NUMBER_OF_DOMAINS
  ENDIF
  !Broadcast the number of elements in the X & Y directions and the number of partitions to the other computational nodes
  CALL MPI_BCAST(NUMBER_GLOBAL_X_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
  CALL MPI_BCAST(NUMBER_GLOBAL_Y_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
  CALL MPI_BCAST(NUMBER_OF_DOMAINS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)
  !IF(MY_COMPUTATIONAL_NODE_NUMBER==0) THEN
    CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"COMPUTATIONAL ENVIRONMENT:",ERR,ERROR,*999)
    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Total number of computaional nodes = ",NUMBER_COMPUTATIONAL_NODES, &
      & ERR,ERROR,*999)
    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  My computational node number = ",MY_COMPUTATIONAL_NODE_NUMBER,ERR,ERROR,*999)
  !ENDIF
    
  !!Initialise the coordinate systems
  !CALL COORDINATE_SYSTEMS_INITIALISE(ERR,ERROR,*999)
  !Start the creation of a new 3D RC coordinate system (as we want a 2D system the default coordinate system is not good enough)
  CALL COORDINATE_SYSTEM_CREATE_START(1,COORDINATE_SYSTEM,ERR,ERROR,*999)
  !Set the coordinate system to be 2D
  CALL COORDINATE_SYSTEM_DIMENSION_SET(COORDINATE_SYSTEM,2,ERR,ERROR,*999)
  !CALL COORDINATE_SYSTEM_DIMENSION_SET(COORDINATE_SYSTEM,3,ERR,ERROR,*999)
  !Finish the creation of the coordinate system
  CALL COORDINATE_SYSTEM_CREATE_FINISH(COORDINATE_SYSTEM,ERR,ERROR,*999)
  !!Initialise the regions
  !CALL REGIONS_INITIALISE(ERR,ERROR,*999)
  !Start the creation of the region
  CALL REGION_CREATE_START(1,REGION,ERR,ERROR,*999)
  !Set the regions coordinate system to the 2D RC coordinate system that we have created
  CALL REGION_COORDINATE_SYSTEM_SET(REGION,COORDINATE_SYSTEM,ERR,ERROR,*999)
  !Finish the creation of the region
  CALL REGION_CREATE_FINISH(REGION,ERR,ERROR,*999)
  
  IMPORT_FIELD=.FALSE..!.TRUE.!.FALSE.
  IF(IMPORT_FIELD) THEN
    CALL FIELD_IO_FILEDS_IMPORT("Test", "Fortran", REGION, MESH, 1, DECOMPOSITION, 1, DECOMPOSITION_CALCULATED_TYPE, &
      & FIELD_STANDARD_VARIABLE_TYPE, FIELD_ARITHMETIC_MEAN_SCALING, ERR, ERROR, *999)
  ELSE
    !Start the creation of a basis (default is trilinear lagrange)
    CALL BASIS_CREATE_START(1,BASIS,ERR,ERROR,*999)  
    !Set the basis to be a bilinear Lagrange basis
    CALL BASIS_NUMBER_OF_XI_SET(BASIS,2,ERR,ERROR,*999)
    !
    !!TEMP: change it to a Simplex basis
    !CALL BASIS_TYPE_SET(BASIS,BASIS_SIMPLEX_TYPE,ERR,ERROR,*999)
    !CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/BASIS_QUADRATIC_SIMPLEX_INTERPOLATION,BASIS_QUADRATIC_SIMPLEX_INTERPOLATION/), &
    !  & ERR,ERROR,*999)
    !
    !TEMP: change it to a biquadratic Lagrange basis
    !CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/BASIS_QUADRATIC_LAGRANGE_INTERPOLATION,BASIS_QUADRATIC_LAGRANGE_INTERPOLATION/), &
    !  & ERR,ERROR,*999)
    !!TEMP: change it to a bicubic Lagrange basis
    !CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/BASIS_CUBIC_LAGRANGE_INTERPOLATION,BASIS_CUBIC_LAGRANGE_INTERPOLATION/),ERR,ERROR,*999)
    !!TEMP: change it to a linear*cubic Lagrange basis
    !CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/BASIS_LINEAR_LAGRANGE_INTERPOLATION,BASIS_CUBIC_LAGRANGE_INTERPOLATION/),ERR,ERROR,*999)
    !!TEMP: change it to a bicubic Hermite basis
    !CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/BASIS_CUBIC_HERMITE_INTERPOLATION,BASIS_CUBIC_HERMITE_INTERPOLATION/),ERR,ERROR,*999)
    !!TEMP: change it to a linear-quadratic-cubic Lagrange basis
    !CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/BASIS_LINEAR_LAGRANGE_INTERPOLATION,BASIS_QUADRATIC_LAGRANGE_INTERPOLATION, &
    !  & BASIS_CUBIC_LAGRANGE_INTERPOLATION/),ERR,ERROR,*999)
    !CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/BASIS_CUBIC_HERMITE_INTERPOLATION,BASIS_CUBIC_HERMITE_INTERPOLATION, &
    !  & BASIS_CUBIC_HERMITE_INTERPOLATION/),ERR,ERROR,*999)
    
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_XI_COLLAPSED,BASIS_COLLAPSED_AT_XI0/),ERR,ERROR,*999)
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_XI_COLLAPSED,BASIS_COLLAPSED_AT_XI1/),ERR,ERROR,*999)
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_COLLAPSED_AT_XI0,BASIS_XI_COLLAPSED/),ERR,ERROR,*999)
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_COLLAPSED_AT_XI1,BASIS_XI_COLLAPSED/),ERR,ERROR,*999)
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_XI_COLLAPSED,BASIS_COLLAPSED_AT_XI0,BASIS_NOT_COLLAPSED/),ERR,ERROR,*999)
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_XI_COLLAPSED,BASIS_COLLAPSED_AT_XI1,BASIS_NOT_COLLAPSED/),ERR,ERROR,*999)
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_XI_COLLAPSED,BASIS_NOT_COLLAPSED,BASIS_COLLAPSED_AT_XI0/),ERR,ERROR,*999)
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_XI_COLLAPSED,BASIS_NOT_COLLAPSED,BASIS_COLLAPSED_AT_XI1/),ERR,ERROR,*999)
    !CALL BASIS_COLLAPSED_XI_SET(BASIS,(/BASIS_COLLAPSED_AT_XI0,BASIS_XI_COLLAPSED,BASIS_XI_COLLAPSED/),ERR,ERROR,*999)
    
    !Finish the creation of the basis
    CALL BASIS_CREATE_FINISH(BASIS,ERR,ERROR,*999)
    !
    CALL BASIS_CREATE_START(2,BASIS2,ERR,ERROR,*999)
    CALL BASIS_NUMBER_OF_XI_SET(BASIS2,2,ERR,ERROR,*999)
    CALL BASIS_INTERPOLATION_XI_SET(BASIS2,(/BASIS_LINEAR_LAGRANGE_INTERPOLATION,BASIS_CUBIC_HERMITE_INTERPOLATION/),ERR,ERROR,*999)
    CALL BASIS_CREATE_FINISH(BASIS2,ERR,ERROR,*999)
    !Define the mesh on the region
    CALL MESH_CREATE_REGULAR(1,REGION,(/0.0_DP,0.0_DP/),(/WIDTH,HEIGHT/),(/NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS/), &
      & BASIS,MESH,ERR,ERROR,*999)
    !CALL MESH_CREATE_REGULAR(1,REGION,(/0.0_DP,0.0_DP,0.0_DP/),(/WIDTH,WIDTH,HEIGHT/),(/NUMBER_GLOBAL_X_ELEMENTS, &
    !  & NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS/),BASIS,MESH,ERR,ERROR,*999)
    
    !CALL MESH_CREATE_START(1,REGION,2,MESH,ERR,ERROR,*999)
    !CALL MESH_NUMBER_OF_ELEMENTS_SET(MESH,2,ERR,ERROR,*999)
    !CALL NODES_CREATE_START(6,REGION,NODES,ERR,ERROR,*999)
    !CALL NODES_CREATE_FINISH(REGION,ERR,ERROR,*999)
    !CALL MESH_TOPOLOGY_ELEMENTS_CREATE_START(2,BASIS,MESH,ELEMENTS,ERR,ERROR,*999)
    !CALL MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_SET(2,ELEMENTS,BASIS2,ERR,ERROR,*999)
    !CALL MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET(1,ELEMENTS,(/1,2,4,5/),ERR,ERROR,*999)
    !CALL MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET(2,ELEMENTS,(/2,3,5,6/),ERR,ERROR,*999)
    !CALL MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH(MESH,ERR,ERROR,*999)
    !CALL MESH_CREATE_FINISH(REGION,MESH,ERR,ERROR,*999)
  
    !
    !Create a decomposition
    CALL DECOMPOSITION_CREATE_START(1,MESH,DECOMPOSITION,ERR,ERROR,*999)
    !Set the decomposition to be a general decomposition with the specified number of domains
    CALL DECOMPOSITION_TYPE_SET(DECOMPOSITION,DECOMPOSITION_CALCULATED_TYPE,ERR,ERROR,*999)
    CALL DECOMPOSITION_NUMBER_OF_DOMAINS_SET(DECOMPOSITION,NUMBER_OF_DOMAINS,ERR,ERROR,*999)
    CALL DECOMPOSITION_CREATE_FINISH(MESH,DECOMPOSITION,ERR,ERROR,*999)
    !!Start to create a default (geometric) field on the region
    CALL FIELD_CREATE_START(1,REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)
    !Set the decomposition to use
    CALL FIELD_MESH_DECOMPOSITION_SET(GEOMETRIC_FIELD,DECOMPOSITION,ERR,ERROR,*999)
    !Set the domain to be used by the field components
    !NB these are needed now as the default mesh component number is 1
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_STANDARD_VARIABLE_TYPE,1,1,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_STANDARD_VARIABLE_TYPE,2,1,ERR,ERROR,*999)
    !CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_STANDARD_VARIABLE_TYPE,3,1,ERR,ERROR,*999)
    !Finish creating the field
    CALL FIELD_CREATE_FINISH(REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)
    
    !CALL CPU_TIMER(USER_CPU,UPDATE_START_USER_TIME,ERR,ERROR,*999)
    !CALL CPU_TIMER(SYSTEM_CPU,UPDATE_START_SYSTEM_TIME,ERR,ERROR,*999)
    
    CALL FIELD_GEOMETRIC_PARAMETERS_UPDATE_FROM_INITIAL_MESH(GEOMETRIC_FIELD,ERR,ERROR,*999)
    !
    !CALL CPU_TIMER(USER_CPU,UPDATE_STOP_USER_TIME,ERR,ERROR,*999)
    !CALL CPU_TIMER(SYSTEM_CPU,UPDATE_STOP_SYSTEM_TIME,ERR,ERROR,*999)
   
    !CALL WRITE_STRING_TWO_VALUE(GENERAL_OUTPUT_TYPE,"Update User time = ",UPDATE_STOP_USER_TIME(1)-UPDATE_START_USER_TIME(1), &
    !  & ", Update System time = ",UPDATE_STOP_SYSTEM_TIME(1)-UPDATE_START_SYSTEM_TIME(1),ERR,ERROR,*999)
  ENDIF
  
  !Create the problem
  IF(.NOT.ASSOCIATED(GEOMETRIC_FIELD)) GEOMETRIC_FIELD=>REGION%FIELDS%FIELDS(1)%PTR
  CALL PROBLEM_CREATE_START(1,REGION,GEOMETRIC_FIELD,PROBLEM,ERR,ERROR,*999)
  !Set the problem to be a standard Laplace problem
  CALL PROBLEM_SPECIFICATION_SET(PROBLEM,PROBLEM_CLASSICAL_FIELD_CLASS,PROBLEM_LAPLACE_EQUATION_TYPE, &
    & PROBLEM_STANDARD_LAPLACE_SUBTYPE,ERR,ERROR,*999)
  !Finish creating the problem
  CALL PROBLEM_CREATE_FINISH(REGION,PROBLEM,ERR,ERROR,*999)

  !Create the problem dependent variables
  CALL PROBLEM_DEPENDENT_CREATE_START(PROBLEM,ERR,ERROR,*999)
  !Finish the problem dependent variables
  CALL PROBLEM_DEPENDENT_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem fixed conditions
  CALL PROBLEM_FIXED_CONDITIONS_CREATE_START(PROBLEM,ERR,ERROR,*999)
  !Set bc's
  CALL PROBLEM_FIXED_CONDITIONS_SET_DOF(PROBLEM,1,PROBLEM_FIXED_BOUNDARY_CONDITION,0.0_DP,ERR,ERROR,*999)
  CALL PROBLEM_FIXED_CONDITIONS_SET_DOF(PROBLEM,(NUMBER_GLOBAL_X_ELEMENTS+1)*(NUMBER_GLOBAL_Y_ELEMENTS+1), &
    & PROBLEM_FIXED_BOUNDARY_CONDITION,1.0_DP,ERR,ERROR,*999)
  !Finish the problem fixed conditions
  CALL PROBLEM_FIXED_CONDITIONS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem solution
  CALL PROBLEM_SOLUTION_CREATE_START(PROBLEM,ERR,ERROR,*999)
  !Set the global matrices sparsity type
  CALL PROBLEM_SOLUTION_GLOBAL_SPARSITY_TYPE_SET(PROBLEM,PROBLEM_SOLUTION_SPARSE_GLOBAL_MATRICES,ERR,ERROR,*999)
  !CALL PROBLEM_SOLUTION_GLOBAL_SPARSITY_TYPE_SET(PROBLEM,PROBLEM_SOLUTION_FULL_GLOBAL_MATRICES,ERR,ERROR,*999)
  !Set the output
  !CALL PROBLEM_SOLUTION_OUTPUT_TYPE_SET(PROBLEM,PROBLEM_SOLUTION_TIMING_OUTPUT,ERR,ERROR,*999)
  CALL PROBLEM_SOLUTION_OUTPUT_TYPE_SET(PROBLEM,PROBLEM_SOLUTION_GLOBAL_MATRIX_OUTPUT,ERR,ERROR,*999)
  !CALL PROBLEM_SOLUTION_OUTPUT_TYPE_SET(PROBLEM,PROBLEM_SOLUTION_ELEMENT_MATRIX_OUTPUT,ERR,ERROR,*999)
  !Finish the problem solution
  CALL PROBLEM_SOLUTION_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Solve the problem
  CALL PROBLEM_SOLVE(PROBLEM,ERR,ERROR,*999)
  
  REGION%FIELDS%NUMBER_OF_FIELDS=1
  CALL FIELD_IO_NODES_EXPORT(REGION%FIELDS, FILE_NAME, METHOD,ERR,ERROR,*999)  
  CALL FIELD_IO_ELEMENTS_EXPORT(REGION%FIELDS, FILE_NAME, METHOD, ERR,ERROR,*999)
  REGION%FIELDS%NUMBER_OF_FIELDS=2
  
  !!Finalise bases
  !CALL BASES_FINALISE(ERR,ERROR,*999)
  !!Finalise the regions
  !CALL REGIONS_FINALISE(ERR,ERROR,*999)
  !!Finalise the coordinate systems
  !CALL COORDINATE_SYSTEMS_FINALISE(ERR,ERROR,*999)
  !!Finalise computational enviroment
  !CALL COMPUTATIONAL_ENVIRONMENT_FINALISE(ERR,ERROR,*999)

  !Output timing summary
  !CALL TIMING_SUMMARY_OUTPUT(ERR,ERROR,*999)

  !Calculate the stop times and write out the elapsed user and system times
  CALL CPU_TIMER(USER_CPU,STOP_USER_TIME,ERR,ERROR,*999)
  CALL CPU_TIMER(SYSTEM_CPU,STOP_SYSTEM_TIME,ERR,ERROR,*999)

  !CALL WRITE_STRING_TWO_VALUE(GENERAL_OUTPUT_TYPE,"User time = ",STOP_USER_TIME(1)-START_USER_TIME(1),", System time = ", &
  !  & STOP_SYSTEM_TIME(1)-START_SYSTEM_TIME(1),ERR,ERROR,*999)
  
  CALL CMISS_FINALISE(ERR,ERROR,*999)

  WRITE(*,'(A)') "Program successfully completed."
  
  STOP
999 CALL CMISS_WRITE_ERROR(ERR,ERROR)
  STOP
  
END PROGRAM OPENCMISSTEST
