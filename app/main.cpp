#include "rustcore.hpp"
#include <iostream>

int main() {
    std::cout << "2 + 3        = " << rs::add(2, 3) << "\n";
    std::cout << "sum          = " << rs::sum({1.5, 2.5, 3.0}) << "\n";
    std::cout << rs::greet("C++") << "\n";

    rs::Counter c(10);
    c.increment();
    std::cout << "counter      = " << c.increment() << "\n";

    int total = 0;
    rs::for_each(5, [&](unsigned i) { total += i; });
    std::cout << "callback sum = " << total << "\n";
}
