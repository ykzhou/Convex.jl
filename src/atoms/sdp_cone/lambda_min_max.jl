#############################################################################
# lambda_min_max.jl
# Handles maximum and minimum eigenvalue of a symmetric positive definite matrix
# (and imposes the constraint that its argument be PSD)
# All expressions and atoms are subtypes of AbstractExpr.
# Please read expressions.jl first.
#############################################################################
export lambda_max, lambda_min

### Lambda max

type LambdaMaxAtom <: AbstractExpr
  head::Symbol
  id_hash::Uint64
  children::(AbstractExpr,)
  size::(Int, Int)

  function LambdaMaxAtom(x::AbstractExpr)
    children = (x,)
    m,n = size(x)
    if m==n
      return new(:lambda_max, hash(children), children, (1,1))
    else
      error("lambda_max can only be applied to a square matrix.")
    end
  end
end

function sign(x::LambdaMaxAtom)
  return Positive()
end

function monotonicity(x::LambdaMaxAtom)
  return (Nondecreasing(),)
end

function curvature(x::LambdaMaxAtom)
  return ConvexVexity()
end

function evaluate(x::LambdaMaxAtom)
  eigvals(evaluate(x.children[1]))[end]
end

lambda_max(x::AbstractExpr) = LambdaMaxAtom(x)

# Create the equivalent conic problem:
#   minimize t
#   subject to
#            tI - A is positive semidefinite
#            A      is positive semidefinite
function conic_form!(x::LambdaMaxAtom, unique_conic_forms)
  if !has_conic_form(unique_conic_forms, x)
    A = x.children[1]
    m, n = size(A)
    t = Variable()
    p = minimize(t, isposdef(t*eye(n) - A), isposdef(A))
    cache_conic_form!(unique_conic_forms, x, p)
  end
  return get_conic_form(unique_conic_forms, x)
end

### Lambda min

type LambdaMinAtom <: AbstractExpr
  head::Symbol
  id_hash::Uint64
  children::(AbstractExpr,)
  size::(Int, Int)

  function LambdaMinAtom(x::AbstractExpr)
    children = (x,)
    m,n = size(x)
    if m==n
      return new(:lambda_min, hash(children), children, (1,1))
    else
      error("lambda_min can only be applied to a square matrix.")
    end
  end
end

function sign(x::LambdaMinAtom)
  return Positive()
end

function monotonicity(x::LambdaMinAtom)
  return (Nondecreasing(),)
end

function curvature(x::LambdaMinAtom)
  return ConcaveVexity()
end

function evaluate(x::LambdaMinAtom)
  eigvals(evaluate(x.children[1]))[1]
end

lambda_min(x::AbstractExpr) = LambdaMinAtom(x)

# Create the equivalent conic problem:
#   maximize t
#   subject to
#            A - tI is positive semidefinite
#            A      is positive semidefinite
function conic_form!(x::LambdaMinAtom, unique_conic_forms)
  if !has_conic_form(unique_conic_forms, x)
    A = x.children[1]
    m, n = size(A)
    t = Variable()
    p = minimize(t, isposdef(A - t*eye(n)), isposdef(A))
    cache_conic_form!(unique_conic_forms, x, p)
  end
  return get_conic_form(unique_conic_forms, x)
end
