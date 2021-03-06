! Learn_dg - A quick and dirty project to deploy a working DG solver
! Copyright (c) 2017, Chris Coutinho
! All rights reserved.
!
! Licensed under the BSD-2 clause license. See LICENSE for details.

module mod_io
    use, intrinsic  :: iso_fortran_env, only: wp=>real64
    use             :: lib_array, only: linspace
    implicit none

    private
    public :: read_gmsh_file_1D, &
        write_out_solution

contains

    subroutine read_gmsh_file_1D(num_nodes, &
            nodes2vertex, &
            cells, &
            points, &
            dg)
        
        !*  Reads the input mesh file (gmsh .msh format) and returns the
        !   number of nodes, element connectivity, and the coordinates of
        !   the nodes in 1D

        integer,  intent(out)                               :: num_nodes    !! Number of nodes in mesh
        integer,  intent(out),  dimension(:),   allocatable :: nodes2vertex !! Array containing node to vertex connectivity (only interesting w.r.t discontinuous galerkin)
        integer,  intent(out),  dimension(:,:), allocatable :: cells        !! Array containing node connectivity of each element
        real(wp), intent(out),  dimension(:),   allocatable :: points       !! Array containing node coordinates
        logical,  intent(in)                                :: dg           !! Logical switch is continuous galerkin or discontinuous galerkin

        integer         :: ii, ios, vertex, num_elements, num_vertexes, d_int
        integer,  dimension(:,:), allocatable :: vertex_conn
        real(wp)        :: d_real
        character(80)   :: filename
        character(80)   :: blank_string

        call get_command_argument(1, filename)

        if ( len_trim(filename) == 0 ) then
            call print_header()
        endif

        open(unit=21, file=filename, iostat=ios, status="old", action="read")
        if ( ios /= 0 ) then
            print*, filename
            print*, ios
            stop "Error opening file "
        endif

        ! Read initial header information - assuming file is in the correct format
        do
            read(21,*) blank_string
            if (trim(blank_string) == '$Nodes') exit
        enddo

        ! Read number of nodes
        read(21,*) num_vertexes
        allocate(points(num_vertexes))

        if ( .not. dg ) then
            num_nodes = num_vertexes
        else
            num_nodes = 2*num_vertexes-2
        endif

        ! Read coordinate information for each vertex
        do ii = 1, num_vertexes
            read(21,*) d_int, points(ii), d_real, d_real
        enddo


        allocate(nodes2vertex(num_nodes))
        nodes2vertex = 0

        if ( dg ) then
            vertex = 1
            do ii = 1, num_nodes

                nodes2vertex(ii) = vertex
                if ( ii == 1 .or. ii == num_nodes ) then
                    vertex = vertex+1
                elseif ( mod(ii, 2) == 0 ) then
                    vertex = vertex+1
                endif

            enddo
        else
            nodes2vertex = [( ii, ii = 1, num_nodes )]
        endif

        ! do ii = 1, num_nodes
        !   print*, ii, nodes2vertex(ii), points(nodes2vertex(ii))
        ! enddo
        ! print*,
        ! stop

        ! Two dummy lines :
        !   $EndNodes
        !   $Elements
        read(21,*)
        read(21,*)

        read(21,*) num_elements
        num_elements = num_elements-2

        allocate(cells(num_elements, 2))
        allocate(vertex_conn(num_elements, 2))

        ! Two dummy lines - Associated with 'point' elements
        read(21,*)
        read(21,*)

        do ii = 1, num_elements
            read(21,*) d_int, d_int, d_int, d_int, d_int, vertex_conn(ii,1:2)
            ! print*, pack(vertex_conn, vertex_conn == nodes2vertex)
        enddo
        ! print*, pack([( ii, ii = 1, num_nodes )], &
        !         nodes2vertex == nodes2vertex(3) &
        !         .or. nodes2vertex == nodes2vertex(5))
        ! stop

        if ( .not. dg ) then
            cells = vertex_conn
        else
            ! do ii = 1, num_elements
            !   cells(ii,:) = pack([( ii, ii = 1, num_nodes )], &
            !                     nodes2vertex == vertex_conn(ii,1))
            !   print*, loc(2._wp)
            !   print*, loc(nodes2vertex == vertex_conn(ii,2))
            !   print*, vertex_conn(ii,:), cells(ii,:)
            !   print*,
            ! enddo
        endif
        ! print*,

        ! do ii = 1, size(points)
        !   print*, points(ii)
        ! enddo
        ! print*,

        close(unit=21, iostat=ios)
        if ( ios /= 0 ) stop "Error closing file unit 21"

        return
    end subroutine read_gmsh_file_1D

    subroutine write_out_solution(num_nodes, points, GlobalX)
        integer,  intent(in)                :: num_nodes
        real(wp), intent(in), dimension(:)  :: points, GlobalX

        integer :: ii, ios

        open(unit=21, file='data.out', iostat=ios, status="replace", action="write")
        if ( ios /= 0 ) then
            print*, ios
            stop "Error opening file data.out"
        endif

        do ii = 1, num_nodes
            write(21,*) points(ii), GlobalX(ii)
        enddo

        close(unit=21, iostat=ios)
        if ( ios /= 0 ) then
            print*, ios
            stop "Error closing file unit data.out"
        endif


        return
    end subroutine write_out_solution

    subroutine print_header()

        ! print*,
        ! print*, '  _____  ______ _____      _             _     '
        ! print*, ' |  __ \|  ____|  __ \    | |           | |    '
        ! print*, ' | |__) | |__  | |  | |___| |_ __ _  ___| | __ '
        ! print*, ' |  _  /|  __| | |  | / __| __/ _` |/ __| |/ / '
        ! print*, ' | | \ \| |____| |__| \__ \ || (_| | (__|   <  '
        ! print*, ' |_|  \_\______|_____/|___/\__\__,_|\___|_|\_\ '
        ! print*,
        ! print*,
        ! print*, ' Developed by Chris Coutinho                   '
        ! print*,

        print*,
        print*, '     ____  __________       __             __   '
        print*, '    / __ \/ ____/ __ \_____/ /_____ ______/ /__ '
        print*, '   / /_/ / __/ / / / / ___/ __/ __ `/ ___/ //_/ '
        print*, '  / _, _/ /___/ /_/ (__  ) /_/ /_/ / /__/ ,<    '
        print*, ' /_/ |_/_____/_____/____/\__/\__,_/\___/_/|_|   '
        print*,
        print*,
        print*, ' Developed by Chris Coutinho                   '
        print*,

        print*, 'No Input file supplied'
        print*,

        stop

    end subroutine print_header

end module mod_io
