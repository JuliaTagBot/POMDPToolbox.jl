import Distributions.MvNormal
import Distributions.Categorical
import Distributions.Multinomial

mvn = MvNormal([1.2,2.3], [1.4 1.0; 1.0 1.2])

@test_approx_eq pdf(mvn, [1.0, 1.0]) 0.04794537749882221

println("There should NOT be a warning between here")
rand(MersenneTwister(12), mvn)
println("and here.")

println("There should be a warning below.")
mn = Multinomial(4, 8)
rand(MersenneTwister(12), mn)

cat = Categorical(3)
rand(MersenneTwister(12), cat)
