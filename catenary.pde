int vieww = 640;
int viewh = 640;

void setup() {
  size(vieww, viewh);
  fill(255);
  background(255,255,255,128);
  loadPixels();
  for ( int i = 0 ; i < pixels.length ; i++ ) pixels[i] = 0;
  updatePixels();
  noLoop();
}

int b1 = -1;
int c1 = -1;
int b2 = -1;
int c2 = -1;
float d = 0.0;
int l = -1;

// Basic hyperbolic trig identities needed for handling the catenary equation
// and inexplicably not available in processing core or any library (?)
float cosh(float x) {
  return 0.5*(exp(x)+exp(-x));
}

float sinh(float x) {
  return 0.5*(exp(x)-exp(-x));
}

float asinh(float x) {
  return log(x + sqrt(1 + x*x));
}

void keyPressed() {
  // Increment the length of the chain: -/= for decrease/increase
  // Hold shift for bigger increments
  if (key == '=') {
    l++;
    background(255);
    redraw();
  }
  else if (key == '+') {
    l += 10;
    background(255);
    redraw();
  }
  else if (key == '-' && l > d + 1) {
    l--;
    background(255);
    redraw();
  }
  else if (key == '_' && l > d + 5) {
    l -= 10;
    background(255);
    redraw();
  }
  else {
    println("No change; l = " + l + ", d = " + d);
  }
}

void mouseDragged() {
  b2 = -1;
  c2 = -1;
  background(128);
  stroke(0);
  line(b1, viewh - c1, pmouseX, pmouseY);
  println("actual p1 = (" + b1 + ", " + c1 + "), p2 = (" + pmouseX + ", " + pmouseY + ")");
  redraw();
}

void mousePressed() {
  background(128);
  b1 = mouseX;
  c1 = viewh - mouseY;
}

void mouseReleased() {
  // When mouse is released, arrange the points where it was clicked and released
  // so that (b1, c1) is on the left
  background(255);
  if (mouseX > b1) {
    // end point is on the left, set (b2, c2) and leave (b1, c1) alone
    b2 = mouseX;
    c2 = viewh - mouseY;
  }
  else {
    // end point on the right, set (b1, c1) to it and (b2, c2) to the start point
    b2 = b1;
    c2 = c1;
    b1 = mouseX;
    c1 = viewh - mouseY;
  }
  d = dist(b1, c1, b2, c2);
  l = (int)(2 * d);
  redraw();
}

float xshift(float a) {
  // Calculate the horizontal shift necessary to put the catenary in the right place.
  // This expression is derived from solving the system:
  //    c1 = a * cosh((b1 - x0)/d) + y0
  //    c2 = a * cosh((b2 - x0)/d) + y0
  // where (b1, c1) and (b2, c2) are the endpoints and x0 and y0 are the horizontal and
  // vertical shifts.
  // (The derivation uses substitution for y0 and the hyperbolic trig identity
  //  for cosh A - cosh B.)
  return ((b1 + b2)/2) - (a * asinh((c2 - c1)/(2*a*sinh((b2-b1)/(2*a)))));
}

float yshift(float a, float b0) {
  // The other half of the solution to the system described above in xshift.
  return c1 - (a * cosh((b1 - b0)/a));
}

float catenaryParameter(float a, float h, float k) {
  // Equation from http://en.wikipedia.org/wiki/Catenary#Determining_parameters
  // (second to last equation in that section)
  return 2*a*sinh(h/(2*a)) - sqrt(l*l - k*k);
}

float catenaryParamDerivative(float a, float h) {
  // Derivative of the above. Used in Newton's method to solve for the parameter a,
  // since (as Wikipedia notes) the equation above is transcendental in a.
  return 2*sinh(h/(2*a)) - (h/a)*cosh(h/(2*a));
}

float newtonGuess(float h, float k) {
  // Return a decent enough guess that Newton's method appears to take about 7 iterations
  // to get within .001 of the correct parameter.
  // Rationale: the equation in catenaryParameter looks similar to the graph of y = 1/(x^2) - C.
  // Guessing too high causes Newton's Method to diverge, as we land out where the slope
  // of the tangent is very shallow. But guessing too low can cause an overflow error
  // because of the exponentiation in sinh.
  // We guess so that sinh(h/2a) is equal to sqrt(l^2 - k^2). 
  // This is a low guess; it puts us on the left side of the root, where y is positive, because
  // of the multiplication by 2a (which is always > 1 because we're measuring in pixels).
  // But that additional factor of 2a won't be enough to cause an overflow.
  return h / (asinh(sqrt(l*l-k*k)));
}

float newton(float h, float k, float guess) {
  // This is a 100% straightforward implementation of Newton's method. I haven't
  // found any instances where it gets anywhere near the max number of iterations; if it does,
  // it will probably fail spectacularly. In my experience, overflows are much more common.
  // Still fails for extremely steep slopes. Not sure I really care.
  float x0 = 1;
  float x1 = guess;
  float fx = 1;
  int iterations = 0;
  println("l = " + l + ", h = " + h + ", k = " + k + ", start x = " + x1);
  while (abs(fx) > 0.001 && iterations < 5000) {
    x0 = x1;
    fx = catenaryParameter(x0, h, k);
    float dfx = catenaryParamDerivative(x0, h);
    x1 = x0 - (fx/dfx);
    iterations += 1;
    println("iteration " + iterations + ", f(x) = " + fx + ", df/dx = " + dfx + ", a = " + x1);
  }
  if (iterations >= 5000) {
    // Newton's method failed, return the guess and hope it's good enough, probably not
    return abs(guess);
  }
  else {
    // Newton's method successful
    return abs(x1);
  }
}

float catenary(float x, float a) {
  // The equation for a catenary, with horizontal and vertical shifts to put the vertex
  // where it needs to be to pass through the endpoints of the user-traced line segment.
  float x0 = xshift(a);
  return a*cosh((x - x0)/a) + yshift(a, x0);
}

void draw() {
  if (b1 >= 0 && b2 >= 0 && c1 >= 0 && c2 >= 0 && d > 5) {
    // Set up vars for the method linked in the catenaryParameter comment
    float h = abs(b2 - b1);
    float k = abs(c1 - c2);
    // Use Newton's Method to determine the parameter
    float a = newton(h, k, newtonGuess(h, k));

    // Store the last point so we can connect them to make a curve
    // instead of a bunch of dots
    float prev_x = b1;
    float prev_y = viewh - c1;

    // Draw the line segment between the anchor points of the catenary
    stroke(192);
    line(b1, viewh - c1, b2, viewh - c2);

    // Draw the catenary for the "chain"
    stroke(0);
    for (int x = b1; x < b2; x++) {
      float y = catenary(x, a);
      println("(" + x + ", " + y + ")");
      line(prev_x, prev_y, x, viewh - y);
      prev_x = x;
      prev_y = viewh - y;
    }
    line(prev_x, prev_y, b2, viewh - c2);
    println("d = " + d + ", l = " + l + ", h = " + h + ", k = " + k);
    println("actual p1 = (" + b1 + ", " + c1 + "), p2 = (" + b2 + ", " + c2 + ")");
    println("a = " + a);
  }
}
