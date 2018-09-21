###############################################################################
#
#   MatrixAlgebra.jl : Generic nxn matrices over rings
#
###############################################################################

export MatrixAlgebra, dimension

###############################################################################
#
#   Data type and parent object methods
#
###############################################################################

parent_type(::Type{MatAlgElem{T}}) where T <: RingElement = MatAlgebra{T}

elem_type(::Type{MatAlgebra{T}}) where {T <: RingElement} = MatAlgElem{T}

Markdown.doc"""
    base_ring{T <: RingElement}(S::AbstractAlgebra.MatAlgebra{T})
> Return the base ring $R$ of the given matrix algebra.
"""
function base_ring(a::AbstractAlgebra.MatAlgebra{T}) where {T <: RingElement}
   a.base_ring::parent_type(T)
end

function check_parent(a::AbstractAlgebra.MatAlgElem{T}, b::AbstractAlgebra.MatAlgElem{T}) where T <: RingElement
  (base_ring(a) != base_ring(b) || dimension(a) != dimension(b)) &&
                error("Incompatible matrix spaces in matrix operation")
end

###############################################################################
#
#   Basic manipulation
#
###############################################################################

function Base.hash(a::MatAlgElem, h::UInt)
   b = 0x6413942b83a26c65%UInt
   for i in 1:rows(a)
      for j in 1:cols(a)
         b = xor(b, xor(hash(a[i, j], h), h))
         b = (b << 1) | (b >> (sizeof(Int)*8 - 1))
      end
   end
   return b
end

dimension(a::MatAlgElem) = size(a.entries, 1)

Markdown.doc"""
    zero(a::AbstractAlgebra.MatAlgebra)
> Construct the zero matrix in the given matrix space.
"""
zero(a::AbstractAlgebra.MatAlgebra) = a()

Markdown.doc"""
    one(a::AbstractAlgebra.MatAlgebra)
> Construct the matrix in the given matrix space with ones down the diagonal
> and zeroes elsewhere.
"""
one(a::AbstractAlgebra.MatAlgebra) = a(1)

###############################################################################
#
#   Similar and eye
#
###############################################################################

function similar(x::MatAlgElem{T}) where T <: RingElement
   R = base_ring(x)
   M = similar(x.entries)
   for i in 1:size(M, 1)
      for j in 1:size(M, 2)
         M[i, j] = zero(R)
      end
   end
   z = MatAlgElem{T}(M)
   z.base_ring = R
   return z
end

function similar(x::MatAlgElem{T}, n::Int) where T <: RingElement
   R = base_ring(x)
   M = similar(x.entries, n, n)
   for i in 1:size(M, 1)
      for j in 1:size(M, 2)
         M[i, j] = zero(R)
      end
   end
   z = MatAlgElem{T}(M)
   z.base_ring = R
   return z
end

function similar(x::MatAlgElem{T}, m::Int, n::Int) where T <: RingElement
   m != n && error("Dimensions don't match in similar")
   R = base_ring(x)
   M = similar(x.entries, n, n)
   for i in 1:size(M, 1)
      for j in 1:size(M, 2)
         M[i, j] = zero(R)
      end
   end
   z = MatAlgElem{T}(M)
   z.base_ring = R
   return z
end

################################################################################
#
#   Size
#
################################################################################

issquare(a::MatAlgElem) = true

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, a::AbstractAlgebra.MatAlgebra)
   print(io, "Matrix Algebra of dimension ")
   print(io, a.n, " over ")
   print(io, base_ring(a))
end

show_minus_one(::Type{AbstractAlgebra.MatAlgElem{T}}) where {T <: RingElement} = false

###############################################################################
#
#   Binary operations
#
###############################################################################

function *(x::AbstractAlgebra.MatAlgElem{T}, y::AbstractAlgebra.MatAlgElem{T}) where {T <: RingElement}
   dimension(x) != dimension(y) && error("Incompatible matrix dimensions")
   A = similar(x)
   C = base_ring(x)()
   for i = 1:rows(x)
      for j = 1:cols(y)
         A[i, j] = base_ring(x)()
         for k = 1:cols(x)
            C = mul!(C, x[i, k], y[k, j])
            A[i, j] = addeq!(A[i, j], C)
         end
      end
   end
   return A
end

###############################################################################
#
#   Ad hoc comparisons
#
###############################################################################

function ==(x::AbstractAlgebra.MatAlgElem, y::Union{Integer, Rational, AbstractFloat})
   n = dimension(x)
   for i = 1:n
      if x[i, i] != y
         return false
      end
   end
   for i = 1:n
      for j = 1:n
         if i != j && !iszero(x[i, j])
            return false
         end
      end
   end
   return true
end

==(x::Union{Integer, Rational, AbstractFloat}, y::AbstractAlgebra.MatAlgElem) = y == x

function ==(x::AbstractAlgebra.MatAlgElem{T}, y::T) where {T <: RingElem}
   n = dimension(x)
   for i = 1:n
      if x[i, i] != y
         return false
      end
   end
   for i = 1:n
      for j = 1:n
         if i != j && !iszero(x[i, j])
            return false
         end
      end
   end
   return true
end

###############################################################################
#
#   Transpose
#
###############################################################################

Markdown.doc"""
    transpose(x::AbstractAlgebra.MatAlgElem)
> Return the transpose of the given matrix.
"""
function transpose(x::MatAlgElem)
   return matrix(base_ring(x), permutedims(x.entries, [2, 1]))
end

Markdown.doc"""
    gram(x::AbstractAlgebra.MatElem)
> Return the Gram matrix of $x$, i.e. if $x$ is an $r\times c$ matrix return
> the $r\times r$ matrix whose entries $i, j$ are the dot products of the
> $i$-th and $j$-th rows, respectively.
"""
function gram(x::AbstractAlgebra.MatAlgElem)
   n = dimension(x)
   z = similar(x)
   for i = 1:n
      for j = 1:n
         z[i, j] = zero(base_ring(x))
         for k = 1:n
            z[i, j] += x[i, k] * x[j, k]
         end
      end
   end
   return z
end

###############################################################################
#
#   Random generation
#
###############################################################################

function rand(S::AbstractAlgebra.MatAlgebra, v...)
   M = S()
   n = dimension(M)
   R = base_ring(S)
   for i = 1:n
      for j = 1:n
         M[i, j] = rand(R, v...)
      end
   end
   return M
end

function randmat_triu(S::AbstractAlgebra.MatAlgebra, v...)
   M = S()
   n = dimension(M)
   R = base_ring(S)
   for i = 1:n
      for j = 1:i - 1
         M[i, j] = R()
      end
      for j = i:n
         M[i, j] = rand(R, v...)
      end
      while M[i, i] == 0
         M[i, i] = rand(R, v...)
      end
   end
   return M
end

function randmat_with_rank(S::Generic.MatAlgebra{T}, rank::Int, v...) where {T <: AbstractAlgebra.RingElement}
   M = S()
   n = dimension(M)
   R = base_ring(S)
   for i = 1:rank
      for j = 1:i - 1
         M[i, j] = R()
      end
      M[i, i] = rand(R, v...)
      while M[i, i] == 0
         M[i, i] = rand(R, v...)
      end
      for j = i + 1:n
         M[i, j] = rand(R, v...)
      end
   end
   for i = rank + 1:n
      for j = 1:n
         M[i, j] = R()
      end
   end
   if n > 1
      for i = 1:4*n
         r1 = rand(1:n)
         r2 = rand(1:n - 1)
         r2 = r2 >= r1 ? r2 + 1 : r2
         d = rand(-5:5)
         for j = 1:n
            M[r1, j] = M[r1, j] + d*M[r2, j]
         end
      end
   end
   return M
end

###############################################################################
#
#   Solve
#
###############################################################################

function solve_lu(M::MatAlgElem{T}, B::MatAlgElem{T}) where {T <: RingElement}
   check_parent(M, B)
   R = base_ring(M)
   MS = Mat{T}(M.entries) # convert to ordinary matrix
   MS.base_ring = R
   BS = Mat{T}(B.entries)
   BS.base_ring = R
   S = solve_lu(MS, BS)
   SA = MatAlgElem{T}(S.entries)
   SA.base_ring = R
   return SA
end

function solve_fflu(M::MatAlgElem{T}, B::MatAlgElem{T}) where {T <: RingElement}
   check_parent(M, B)
   R = base_ring(M)
   MS = Mat{T}(M.entries) # convert to ordinary matrix
   MS.base_ring = R
   BS = Mat{T}(B.entries)
   BS.base_ring = R
   S, d = solve_fflu(MS, BS)
   SA = MatAlgElem{T}(S.entries)
   SA.base_ring = R
   return SA, d
end

###############################################################################
#
#   Minimal polynomial
#
###############################################################################

Markdown.doc"""
    minpoly{T <: RingElement}(S::Ring, M::MatAlgElem{T}, charpoly_only = false)
> Returns the minimal polynomial $p$ of the matrix $M$. The polynomial ring $S$
> of the resulting polynomial must be supplied and the matrix must be square.
"""
function minpoly(S::Ring, M::MatAlgElem{T}, charpoly_only::Bool = false) where {T <: RingElement}
   MS = Mat{T}(M.entries) # convert to ordinary matrix
   MS.base_ring = base_ring(M)
   return minpoly(S, MS, charpoly_only)
end

###############################################################################
#
#   Parent object call overload
#
###############################################################################

function (a::MatAlgebra{T})() where {T <: RingElement}
   R = base_ring(a)
   entries = Array{T}(undef, a.n, a.n)
   for i = 1:a.n
      for j = 1:a.n
         entries[i, j] = zero(R)
      end
   end
   z = MatAlgElem{T}(entries)
   z.base_ring = R
   return z
end

function (a::MatAlgebra{T})(b::S) where {S <: RingElement, T <: RingElement}
   R = base_ring(a)
   entries = Array{T}(undef, a.n, a.n)
   rb = R(b)
   for i = 1:a.n
      for j = 1:a.n
         if i != j
            entries[i, j] = zero(R)
         else
            entries[i, j] = rb
         end
      end
   end
   z = MatAlgElem{T}(entries)
   z.base_ring = R
   return z
end

function (a::MatAlgebra{T})(b::MatAlgElem{T}) where {T <: RingElement}
   parent(b) != a && error("Unable to coerce matrix")
   return b
end

function (a::MatAlgebra{T})(b::Array{S, 2}) where {S <: RingElement, T <: RingElement}
   R = base_ring(a)
   _check_dim(a.n, a.n, b)
   entries = Array{T}(undef, a.n, a.n)
   for i = 1:a.n
      for j = 1:a.n
         entries[i, j] = R(b[i, j])
      end
   end
   z = MatAlgElem{T}(entries)
   z.base_ring = R
   return z
end

function (a::MatAlgebra{T})(b::Array{S, 1}) where {S <: RingElement, T <: RingElement}
   _check_dim(a.n, a.n, b)
   b = Array{S, 2}(transpose(reshape(b, a.n, a.n)))
   z = a(b)
   return z
end

###############################################################################
#
#   MatrixSpace constructor
#
###############################################################################

Markdown.doc"""
    MatrixAlgebra(R::AbstractAlgebra.Ring, n::Int, cached::Bool = true)
> Return parent object corresponding to the ring of $n\times n$ matrices over
> the ring $R$. If `cached == true` (the default), the returned parent object
> is cached so that it can returned by future calls to the constructor with the
> same dimensions and base ring.
"""
function MatrixAlgebra(R::AbstractAlgebra.Ring, n::Int, cached::Bool = true)
   T = elem_type(R)
   return MatAlgebra{T}(R, n, cached)
end
