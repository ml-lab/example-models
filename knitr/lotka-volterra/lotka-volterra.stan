functions {
  real[] dz_dt(real t,       // time
               real[] z,     // system state {prey, predator}
               real[] theta, // parameters
               real[] x_r,   // unused data
               int[] x_i) {
    real u = z[1];
    real v = z[2];

    real alpha = theta[1];
    real beta = theta[2];
    real gamma = theta[3];
    real delta = theta[4];

    real du_dt = (alpha - beta * v) * u;
    real dv_dt = (-gamma + delta * u) * v;

    return { du_dt, dv_dt };
  }
}
data {
  int<lower = 0> N;         // number of measurement times
  real ts[N];               // measurement times > 0
  real y0[2];               // initial measured populations
  real<lower = 0> y[N, 2];  // measured populations
}
parameters {
  real<lower = 0> theta[4];  // theta = { alpha, beta, gamma, delta }
  real<lower = 0> z0[2];     // initial population
  real<lower = 0> sigma[2];  // measurement errors
}
transformed parameters {
  // population for remaining years
  real z[N, 2]
    = integrate_ode_rk45(dz_dt, z0, 0, ts, theta,
                         rep_array(0.0, 0), rep_array(0, 0),
                         1e-5, 1e-3, 5e2);
}
model {
  // priors
  sigma ~ lognormal(0, 0.5);
  theta[{1, 3}] ~ normal(1, 0.5);
  theta[{2, 4}] ~ normal(0.05, 0.05);

  z0[1] ~ lognormal(log(30), 1);
  z0[2] ~ lognormal(log(5), 1);

  // likelihood
  for (k in 1:2) {
    y0[k] ~ lognormal(log(z0[k]), sigma[k]);
    y[ , k] ~ lognormal(log(z[, k]), sigma[k]);
  }
}
generated quantities {
  real y0_rep[2];
  real y_rep[N, 2];

  for (k in 1:2) {
    y0_rep[k] = lognormal_rng(log(z0[k]), sigma[k]);
    for (n in 1:N)
      y_rep[n, k] = lognormal_rng(log(z[n, k]), sigma[k]);
  }
}
