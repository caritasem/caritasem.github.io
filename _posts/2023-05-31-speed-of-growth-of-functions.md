---
layout: article
title:  "不同函数的增长曲线"
date:   2023-05-31 20:00:07 +0800
categories: complexity
---

 算法的复杂度，也就是算法的时间或空间量度，记作：$T(n)= O(f(n))$。
 用大写$O()$来体现算法复杂度的记法，我们称之为 大O记法。
 一般情况下，随着输入规模n的增大，$T(n)$增长最慢的算法为最优算法。

## 函数增长曲线

![](/assets/posts/202305/function_growth.svg) 
A log-log-scaled plot of different functions (including polynomially and exponentially growing ones as well as the factorial) to illustrate the speed of growth of these functions. Exponential functions grow very fast, so that an algorithm which needs $ ~ 2^x $ steps to solve an optimization problem of size $x$ quickly becomes infeasible.


## Big-O Complexity Chart

常见的算法时间复杂度有： $O(1) < O(logn) < O(n) < O(nlogn) < O(n²) < O(n³) < O(2^n) < O(n!)$
 复杂度对应的名称分别是：常数阶，对数阶，线性阶，二维阶，平方阶，立方阶，指数阶，乘阶阶

<style type="text/css">

.gray {
  border: 1px solid #adadad;
  color: black;
  background-color: #e3e3e3;
}

.green {
  border: 1px solid #286500;
  color: black;
  background-color: #53d000;
}

.yellow-green {
  border: 1px solid #286500;
  color: black;
  background-color: #C8EA00;
}

.yellow {
  border: 1px solid #6f6e00;
  color: black;
  background-color: yellow;
}

.orange {
  border: 1px solid #b20000;
  color: black;
  background-color: #FFC543;
}

.red {
  border: 1px solid #b20000;
  color: black;
  background-color: #ff8989;
}
</style>
<table id="legend" class="table">
    <tbody>
        <tr>
        <td><code class="red">Horrible</code></td>
        <td><code class="orange">Bad</code></td>
        <td><code class="yellow">Fair</code></td>
        <td><code class="yellow-green">Good</code></td>
        <td><code class="green">Excellent</code></td>
        </tr>
    </tbody>
</table>

![](/assets/posts/202305/complexity.svg) 



## 一些常用数组排序算法的时间复杂度和空间复杂度

<table class="table table-bordered table-striped">
    <tbody><tr>
      <th>Algorithm</th>
      <th colspan="3">Time Complexity</th>
      <th>Space Complexity</th>
    </tr>
    <tr>
      <th></th>
      <th>Best</th>
      <th>Average</th>
      <th>Worst</th>
      <th>Worst</th>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Quicksort">Quicksort</a></td>
      <td><code class="orange">Ω(n log(n))</code></td>
      <td><code class="orange">Θ(n log(n))</code></td>
      <td><code class="red">O(n^2)</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Merge_sort">Mergesort</a></td>
      <td><code class="orange">Ω(n log(n))</code></td>
      <td><code class="orange">Θ(n log(n))</code></td>
      <td><code class="orange">O(n log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Timsort">Timsort</a></td>
      <td><code class="yellow">Ω(n)</code></td>
      <td><code class="orange">Θ(n log(n))</code></td>
      <td><code class="orange">O(n log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Heapsort">Heapsort</a></td>
      <td><code class="orange">Ω(n log(n))</code></td>
      <td><code class="orange">Θ(n log(n))</code></td>
      <td><code class="orange">O(n log(n))</code></td>
      <td><code class="green">O(1)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Bubble_sort">Bubble Sort</a></td>
      <td><code class="yellow">Ω(n)</code></td>
      <td><code class="red">Θ(n^2)</code></td>
      <td><code class="red">O(n^2)</code></td>
      <td><code class="green">O(1)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Insertion_sort">Insertion Sort</a></td>
      <td><code class="yellow">Ω(n)</code></td>
      <td><code class="red">Θ(n^2)</code></td>
      <td><code class="red">O(n^2)</code></td>
      <td><code class="green">O(1)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Selection_sort">Selection Sort</a></td>
      <td><code class="red">Ω(n^2)</code></td>
      <td><code class="red">Θ(n^2)</code></td>
      <td><code class="red">O(n^2)</code></td>
      <td><code class="green">O(1)</code></td>
    </tr>
    <tr>
      <td><a href="https://en.wikipedia.org/wiki/Tree_sort">Tree Sort</a></td>
      <td><code class="orange">Ω(n log(n))</code></td>
      <td><code class="orange">Θ(n log(n))</code></td>
      <td><code class="red">O(n^2)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Shellsort">Shell Sort</a></td>
      <td><code class="orange">Ω(n log(n))</code></td>
      <td><code class="red">Θ(n(log(n))^2)</code></td>
      <td><code class="red">O(n(log(n))^2)</code></td>
      <td><code class="green">O(1)</code></td>
    </tr>
    <tr>
      <td><a rel="tooltip" title="Only for integers. k is a number of buckets" href="http://en.wikipedia.org/wiki/Bucket_sort">Bucket Sort</a></td>
      <td><code class="green">Ω(n+k)</code></td>
      <td><code class="green">Θ(n+k)</code></td>
      <td><code class="red">O(n^2)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a rel="tooltip" title="Constant number of digits 'k'" href="http://en.wikipedia.org/wiki/Radix_sort">Radix Sort</a></td>
      <td><code class="green">Ω(nk)</code></td>
      <td><code class="green">Θ(nk)</code></td>
      <td><code class="green">O(nk)</code></td>
      <td><code class="yellow">O(n+k)</code></td>
    </tr>
    <tr>
      <td><a rel="tooltip" title="Difference between maximum and minimum number 'k'" href="https://en.wikipedia.org/wiki/Counting_sort">Counting Sort</a></td>
      <td><code class="green">Ω(n+k)</code></td>
      <td><code class="green">Θ(n+k)</code></td>
      <td><code class="green">O(n+k)</code></td>
      <td><code class="yellow">O(k)</code></td>
    </tr>
    <tr>
      <td><a href="https://en.wikipedia.org/wiki/Cubesort">Cubesort</a></td>
      <td><code class="yellow">Ω(n)</code></td>
      <td><code class="orange">Θ(n log(n))</code></td>
      <td><code class="orange">O(n log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
   </tr>
</tbody></table>

## 一些常用数据结构的时间复杂度和空间复杂度

<table class="table table-bordered table-striped">
    <tbody><tr>
      <th>Data Structure</th>
      <th colspan="8">Time Complexity</th>
      <th>Space Complexity</th>
    </tr>
    <tr>
      <th></th>
      <th colspan="4">Average</th>
      <th colspan="4">Worst</th>
      <th>Worst</th>
    </tr>
    <tr>
      <th></th>
      <th>Access</th>
      <th>Search</th>
      <th>Insertion</th>
      <th>Deletion</th>
      <th>Access</th>
      <th>Search</th>
      <th>Insertion</th>
      <th>Deletion</th>
      <th></th>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Array_data_structure">Array</a></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Stack_(abstract_data_type)">Stack</a></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Queue_(abstract_data_type)">Queue</a></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Singly_linked_list#Singly_linked_lists">Singly-Linked List</a></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Doubly_linked_list">Doubly-Linked List</a></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="yellow">Θ(n)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="green">O(1)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Skip_list">Skip List</a></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="orange">O(n log(n))</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Hash_table">Hash Table</a></td>
      <td><code class="gray">N/A</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="green">Θ(1)</code></td>
      <td><code class="gray">N/A</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Binary_search_tree">Binary Search Tree</a></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="https://en.wikipedia.org/wiki/Cartesian_tree">Cartesian Tree</a></td>
      <td><code class="gray">N/A</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="gray">N/A</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/B_tree">B-Tree</a></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/Red-black_tree">Red-Black Tree</a></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="https://en.wikipedia.org/wiki/Splay_tree">Splay Tree</a></td>
      <td><code class="gray">N/A</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="gray">N/A</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/AVL_tree">AVL Tree</a></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow-green">O(log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
    <tr>
      <td><a href="http://en.wikipedia.org/wiki/K-d_tree">KD Tree</a></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow-green">Θ(log(n))</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
      <td><code class="yellow">O(n)</code></td>
    </tr>
</tbody></table>

---
参考
 - https://thomasweise.github.io/aitoa/aitoa.html
 - https://www.bigocheatsheet.com/