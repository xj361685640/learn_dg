module misc
  use base_types, only: dp
  implicit none

  abstract interface
    pure function func1(xx) result(yy)
      import dp
      real(dp), intent(in), dimension(:):: xx
      real(dp), dimension(:), allocatable:: yy
    end function func1

    pure function func2(xx, aa) result(yy)
      import dp
      real(dp), intent(in), dimension(:):: xx, aa
      real(dp), dimension(:), allocatable:: yy
    end function func2
  end interface

contains

  pure function myfun(x) result(y)
    real(dp), intent(in), dimension(:):: x
    real(dp), dimension(:), allocatable:: y

    allocate(y(size(x)))
    y = x**2.0d0

    return
  end function myfun


  pure function f1(x) result(y)
    real(dp), intent(in), dimension(:):: x
    real(dp), dimension(:), allocatable:: y

    allocate(y(size(x)))
    y = 2.0d0 * x

    return
  end function f1


  pure function f2(x) result(y)
    real(dp), intent(in), dimension(:):: x
    real(dp), dimension(:), allocatable:: y

    allocate(y(size(x)))
    y = 3.0d0 * x**2.0d0

    return
  end function f2


  pure function fancy (func, x) result(y)
    real(dp), intent(in), dimension(:):: x
    real(dp), dimension(:), allocatable:: y

    interface AFunc
        pure function func(xx) result(yy)
        import dp
        real(dp), intent(in), dimension(:):: xx
        real(dp), dimension(:), allocatable:: yy
      end function func
    end interface AFunc

    allocate(y(size(x)))
    y = func(x) + 3.3d0 * x

    return
  end function fancy

end module misc
