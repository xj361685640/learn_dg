! Learn_dg - A quick and dirty project to deploy a working DG solver
! Copyright (c) 2017, Chris Coutinho
! All rights reserved.
!
! Licensed under the BSD-2 clause license. See LICENSE for details.

program driver2D
    use, intrinsic  :: iso_fortran_env, only: wp=>real64
    use             :: mod_linalg, only: linsolve_quick, eye
    use             :: mod_misc, only: r8mat_print
    use             :: mod_legendre, only: getXY
    use             :: mod_assembly, only: assembleElementalMatrix, assemble
    implicit none

    integer :: ii
    ! integer, parameter :: N = 4
    ! integer, parameter :: N = 9
    integer, parameter :: N = 16

    real(wp), dimension(N,2)  :: xy
    real(wp), dimension(:,:), allocatable :: points
    real(wp), dimension(N,N)  :: Ie

    real(wp), dimension(N)    :: GlobalB, GlobalX
    real(wp), dimension(N,N)  :: GlobalA
    ! real(wp), dimension(9)    :: GlobalB, GlobalX
    ! real(wp), dimension(9,9)  :: GlobalA
    ! real(wp), dimension(15)    :: GlobalB, GlobalX
    ! real(wp), dimension(15,15)  :: GlobalA
    ! real(wp), dimension(16)    :: GlobalB, GlobalX
    ! real(wp), dimension(16,16)  :: GlobalA


    integer,  dimension(1,N)  :: elem
    ! integer,  dimension(4,4)  :: elem
    ! integer,  dimension(2,9)  :: elem
    ! integer, dimension(1, 16) :: elem

    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! !!!!!! Bi-linear quads !!!!!!!
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Element connection(s) for 4 bi-linear quadrilaterals
    ! elem(1,:) = [1, 2, 3, 4]
    ! elem(2,:) = [2, 5, 6, 3]
    ! elem(3,:) = [5, 7, 8, 6]
    ! elem(4,:) = [7, 9, 10, 8]

    ! Get base xi/eta coordinates for bi-linear quadrilateral
    ! xy = getXY(N)

    ! Adjust for bi-linear quad
    ! xy(:,1) = [0._wp, 1._wp, 1.6_wp, 0._wp]
    ! xy(:,2) = [-1._wp, -2._wp, 5._wp, 3._wp]
    ! xy(:,1) = [0._wp, 0.03333_wp, 0.03333_wp, 0._wp]
    ! xy(:,2) = [0._wp, 0._wp, 0.03333_wp, 0.03333_wp]
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! !!!!!! Bi-linear quads !!!!!!!
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! !!!!!! Bi-quadratic quads !!!!!!!
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Element connection(s) for 2 bi-quadratic quadrilaterals
    ! elem(1,:) = [1, 2, 5, 6, 7, 8, 9, 10, 11]
    ! elem(2,:) = [2, 3, 4, 5, 12, 13, 14, 8, 15]

    ! Get base xi/eta coordinates for bi-quadratic quadrilateral
    ! xy = getXY(N)

    ! Adjust for bi-quadratic quad
    ! xy(:,1) = [0._wp, 0.03333_wp, 0.03333_wp, 0._wp, 0.016667_wp, 0.03333_wp, 0.016667_wp, 0._wp, 0.016667_wp]
    ! xy(:,2) = [0._wp, 0._wp, 0.03333_wp, 0.03333_wp, 0._wp, 0.016667_wp, 0.03333_wp, 0.016667_wp, 0.016667_wp]
    ! xy(1,:) = [-1.25_wp, -0.8_wp]
    ! xy(6,:) = [0.75_wp, 0.1_wp]
    ! xy(9,:) = [-0.25_wp, 0.25_wp]
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! !!!!!! Bi-quadratic quads !!!!!!!
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! !!!!!! Bi-cubic quads !!!!!!!
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Element connection(s) for 2 bi-cubic quadrilaterals
    ! elem(1,:) = [(ii, ii=1,16)]

    ! Get base xi/eta coordinates for bi-cubic quadrilateral
    ! xy = getXY(N)

    ! Adjust for bi-cubic quad
    ! xy(:,1) = [0._wp, 0.03333_wp, 0.03333_wp, 0._wp, 0.016667_wp, 0.03333_wp, 0.016667_wp, 0._wp, 0.016667_wp]
    ! xy(:,2) = [0._wp, 0._wp, 0.03333_wp, 0.03333_wp, 0._wp, 0.016667_wp, 0.03333_wp, 0.016667_wp, 0.016667_wp]
    ! xy(1,:) = [-1.25_wp, -0.8_wp]
    ! xy(6,:) = [0.75_wp, 0.1_wp]
    ! xy(9,:) = [-0.25_wp, 0.25_wp]
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! !!!!!! Bi-cubic quads !!!!!!!
    ! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    ! GlobalA = 0._wp
    ! do ii = 1, size(elem, 1)
    !   Ie = - assembleElementalMatrix(N, 1, 1, xy) - assembleElementalMatrix(N, 2, 2, xy)
    !   GlobalA(elem(ii,:), elem(ii,:)) = GlobalA(elem(ii,:), elem(ii,:)) + Ie
    ! enddo

    ! elem(1,:) = [1, 5, 9, 8]
    ! elem(2,:) = [5, 2, 6, 9]
    ! elem(3,:) = [9, 6, 3, 7]
    ! elem(4,:) = [8, 9, 7, 4]

    elem(1,:) = [(ii, ii = 1,N)]

    ! call r8mat_print(size(elem,1), size(elem,2), dble(elem), "cells")

    points = getXY(N)
    ! call r8mat_print(size(points,1), size(points,2), points, 'points')


    call assemble(points, elem, 1._wp, [0._wp, 0._wp], GlobalA)
    select case (N)
    case (9)
        GlobalA( [1, 2, 3, 4, 6, 8], : ) = 0._wp
        GlobalA( [1, 2, 3, 4, 6, 8], [1, 2, 3, 4, 6, 8] ) = eye(6)

        GlobalB = 0._wp
        GlobalB( [1, 4, 8] ) = 1._wp
    case (16)
        GlobalA( [1, 2, 3, 4, 7, 8, 11, 12], : ) = 0._wp
        GlobalA( [1, 2, 3, 4, 7, 8, 11, 12], [1, 2, 3, 4, 7, 8, 11, 12] ) = eye(8)

        GlobalB = 0._wp
        GlobalB ( [1, 4, 11, 12] ) = 1._wp
    end select


    ! Zero-out the row corresponding with BCs and set A(ii,ii) to 1.0 forall ii
    ! GlobalA( [1, 4, 9, 10], : ) = 0._wp
    ! GlobalA( [1, 4, 9, 10], [1, 4, 9, 10] ) = eye(4)
    ! GlobalA( [1, 6, 10, 3, 4, 13], : ) = 0._wp
    ! GlobalA( [1, 6, 10, 3, 4, 13], [1, 6, 10, 3, 4, 13] ) = eye(6)
    ! GlobalA( [1, 2, 7, 8, 3, 4, 11, 12], : ) = 0._wp
    ! GlobalA( [1, 2, 7, 8, 3, 4, 11, 12], [1, 2, 7, 8, 3, 4, 11, 12] ) = eye(8)
    ! call r8mat_print(size(GlobalA,1), size(GlobalA,2), GlobalA, "Global Stiffness Matrix:")

    ! Set BCs (zero everywhere, 1 on left boundary)
    ! GlobalB = 0._wp
    ! GlobalB( [1, 4] ) = 1._wp
    ! GlobalB( [1, 4, 8] ) = 1._wp
    ! GlobalB ( [1, 4, 11, 12] ) = 1._wp

    ! Solve linear system
    call linsolve_quick( &
        size(GlobalA, 1), GlobalA, &
        size(GlobalB,1), GlobalB, &
        GlobalX)
    call r8mat_print( &
        size(GlobalX,1), 1, GlobalX, "Solution Vector:")

end program driver2D
