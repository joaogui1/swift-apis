// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Returns the L1 loss between predictions and expectations.
/// Given`predicted` and `expected`, the L2 loss is computed as follows:
///  `reduction(abs(predicted - expected))`
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func l1Loss<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _sum
) -> Tensor<Scalar> {
    reduction(abs(expected - predicted))
}

/// Returns the L2 loss between predictions and expectations.
/// Given`predicted` and `expected`, the L2 loss is computed as follows:
///  `reduction((predicted - expected)^2)`
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func l2Loss<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _sum
) -> Tensor<Scalar> {
    reduction((expected - predicted).squared())
}

/// Computes the mean of absolute difference between labels and predictions.
/// `loss = mean(abs(expected - predicted))`
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
@differentiable(wrt: predicted)
public func meanAbsoluteError<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>
) -> Tensor<Scalar> {
    l1Loss(predicted: predicted, expected: expected, reduction: _mean)
}

/// Computes the mean of squares of errors between labels and predictions.
/// `loss = mean(square(expected - predicted))`
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
@differentiable(wrt: predicted)
public func meanSquaredError<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>
) -> Tensor<Scalar> {
    l2Loss(predicted: predicted, expected: expected, reduction: _mean)
}

/// Computes the mean squared logarithmic error between `predicted` and `expected`
///  `loss = square(log(expected) - log(predicted))`
///
/// - Note: Negative tensor entries will be clamped at `0` to avoid undefined
///   logarithmic behavior, as `log(_:)` is undefined for negative reals.
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
@differentiable(wrt: predicted)
public func meanSquaredLogarithmicError<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>
) -> Tensor<Scalar> {
    let logPredicted = log(max(predicted, Tensor(0)) + 1)
    let logExpected = log(max(expected, Tensor(0)) + 1)
    return l2Loss(predicted: logPredicted, expected: logExpected, reduction: _mean)
}

/// Computes the mean absolute percentage error between `predicted` and `expected`.
///  `loss = 100 * mean(abs((expected - predicted) / abs(expected)))`
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
@differentiable(wrt: predicted)
public func meanAbsolutePercentageError<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>
) -> Tensor<Scalar> {
    100 * abs((expected - predicted) / abs(expected)).mean()
}

/// Computes the hinge loss between `predicted` and `expected`.
///  `loss = reduction(max(0, 1 - predicted * expected))` 
///  `expected` values are expected to be -1 or 1.
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func hingeLoss<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _mean
) -> Tensor<Scalar> {
    reduction(max(Tensor(0), Tensor(1) - expected * predicted))
}

/// Computes the squared hinge loss between `predicted` and `expected`.
///  `loss = reduction(square(max(0, 1 - predicted * expected)))`
///  `expected` values are expected to be -1 or 1.
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func squaredHingeLoss<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _mean
) -> Tensor<Scalar> {
    reduction(hingeLoss(predicted: predicted, expected: expected).squared())
}

/// Computes the categorical hinge loss between `predicted` and `expected`.
///  `loss = maximum(negative - positive + 1, 0)`
///   where `negative = max((1 - expected) * predicted)` and 
///  `positive = sum(predicted * expected)`
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func categoricalHingeLoss<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _mean
) -> Tensor<Scalar> {
    let positive = (expected * predicted).sum(alongAxes: -1)
    let negative = ((Tensor(1) - expected) * predicted).max(alongAxes: -1)
    return reduction(max(Tensor(0), negative - positive + Tensor(1)))
}

/// Computes the logarithm of the hyperbolic cosine of the prediction error.
///  `logcosh = log((exp(x) + exp(-x))/2)`,
///   where x is the error `predicted - expected`
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func logCoshLoss<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _mean
) -> Tensor<Scalar> {
    let x = predicted - expected
    return reduction(x + softplus(Tensor(-2) * x) - log(Tensor(2)))
}

/// Computes the Poisson loss between predicted and expected
///  The Poisson loss is the mean of the elements of the `Tensor`
///  `predicted - expected * log(predicted)`.
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func poissonLoss<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _mean
) -> Tensor<Scalar> {
    reduction(predicted - expected * log(predicted))
}

/// Returns the Kullback-Leibler divergence (KL divergence) between between expectations and
/// predictions. 
/// Given two distributions `y_pred` and `y_true`, KL divergence is computed as follows:
/// `reduction(y_true * log(y_true / y_pred))`
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func kullbackLeiblerDivergence<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _sum
) -> Tensor<Scalar> {
    reduction(expected * log(expected / predicted))
}

/// Returns the softmax cross entropy (categorical cross entropy) between logits and labels.
///
/// - Parameters:
///   - logits: One-hot encoded outputs from a neural network.
///   - labels: Indices (zero-indexed) of the correct outputs.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: logits)
public func softmaxCrossEntropy<Scalar: TensorFlowFloatingPoint>(
    logits: Tensor<Scalar>,
    labels: Tensor<Int32>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _mean
) -> Tensor<Scalar> {
    reduction(softmaxCrossEntropyHelper(logits: logits, labels: labels))
}

@inlinable
@differentiable(wrt: logits)
func softmaxCrossEntropyHelper<Scalar: TensorFlowFloatingPoint>(
    logits: Tensor<Scalar>,
    labels: Tensor<Int32>
) -> Tensor<Scalar> {
    _Raw.sparseSoftmaxCrossEntropyWithLogits(features: logits, labels: labels).loss
}

@inlinable
@derivative(of: softmaxCrossEntropyHelper(logits:labels:))
func _vjpSoftmaxCrossEntropyHelper<Scalar: TensorFlowFloatingPoint>(
    logits: Tensor<Scalar>,
    labels: Tensor<Int32>
) -> (value: Tensor<Scalar>, pullback: (Tensor<Scalar>) -> Tensor<Scalar>) {
    let (loss, grad) = _Raw.sparseSoftmaxCrossEntropyWithLogits(features: logits, labels: labels)
    return (loss, { $0.expandingShape(at: -1) * grad })
}

/// Returns the softmax cross entropy (categorical cross entropy) between logits and labels.
/// Given the logits and probabilities, the softmax cross entropy computes `reduction(-softmax(logits) * log(p))`
/// Where softmax(x) = `exp(x) / sum(exp(x))`
///
/// - Parameters:
///   - logits: Unscaled log probabilities from a neural network.
///   - probabilities: Probability values that correspond to the correct output. Each row must be a
///                    valid probability distribution.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: logits)
public func softmaxCrossEntropy<Scalar: TensorFlowFloatingPoint>(
    logits: Tensor<Scalar>,
    probabilities: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _mean
) -> Tensor<Scalar> {
    reduction(softmaxCrossEntropyHelper(logits: logits, probabilities: probabilities))
}

@inlinable
@differentiable(wrt: logits)
func softmaxCrossEntropyHelper<Scalar: TensorFlowFloatingPoint>(
    logits: Tensor<Scalar>,
    probabilities: Tensor<Scalar>
) -> Tensor<Scalar> {
    _Raw.softmaxCrossEntropyWithLogits(features: logits, labels: probabilities).loss
}

@inlinable
@derivative(of: softmaxCrossEntropyHelper(logits:probabilities:), wrt: logits)
func _vjpSoftmaxCrossEntropyHelper<Scalar: TensorFlowFloatingPoint>(
    logits: Tensor<Scalar>,
    probabilities: Tensor<Scalar>
) -> (value: Tensor<Scalar>, pullback: (Tensor<Scalar>) -> Tensor<Scalar>) {
    let (loss, grad) = _Raw.softmaxCrossEntropyWithLogits(features: logits, labels: probabilities)
    return (loss, { $0.expandingShape(at: -1) * grad })
}

/// Returns the sigmoid cross entropy (binary cross entropy) between logits and labels.
/// Given the logits and probabilites, the sigmoid cross entropy computes `reduction(-sigmoid(logits) * log(p))`
/// Where sigmoid(x) = `1 / (1 + exp(-x))`
///
/// The reduction is reduced over all elements. If reduced over batch size is intended, please
/// consider to scale the loss.
///
/// - Parameters:
///   - logits: The unscaled output of a neural network.
///   - labels: Integer values that correspond to the correct output.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: logits)
public func sigmoidCrossEntropy<Scalar: TensorFlowFloatingPoint>(
    logits: Tensor<Scalar>,
    labels: Tensor<Scalar>,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _mean
) -> Tensor<Scalar> {
    // This numerically stable implementation is based on the TensorFlow Python API.
    let maxLogitsWithZero = max(logits, Tensor(0))
    let negAbsLogits = max(logits, -logits) // Custom `abs` to compute gradients at `0`.
    return reduction(maxLogitsWithZero - logits * labels + log1p(exp(-negAbsLogits)))
}

/// Returns the Huber loss between predictions and expectations.
///
/// For each value `x` in the difference `expected - predicted`, the loss is:
/// - `0.5 * x^2` if `abs(x) <= δ`.
/// - `0.5 * δ^2 + δ * (|x| - δ)` otherwise.
///
/// - Source: [Wikipedia article](https://en.wikipedia.org/wiki/Huber_loss).
///
/// - Parameters:
///   - predicted: Predicted outputs from a neural network.
///   - expected: Expected values, i.e. targets, that correspond to the correct output.
///   - delta: A floating point scalar representing the point where the Huber loss function changes
///     from quadratic to linear.
///   - reduction: Reduction to apply on the computed element-wise loss values.
@differentiable(wrt: predicted)
public func huberLoss<Scalar: TensorFlowFloatingPoint>(
    predicted: Tensor<Scalar>,
    expected: Tensor<Scalar>,
    delta: Scalar,
    reduction: @differentiable (Tensor<Scalar>) -> Tensor<Scalar> = _sum
) -> Tensor<Scalar> {
    let error = expected - predicted
    let absError = abs(error)
    let quadratic = min(absError, delta)
    let linear = absError - quadratic
    return reduction((0.5 * quadratic * quadratic) + (delta * linear))
}

/// Workaround for TF-1030 so that we can use sum as a default argument for reductions.
/// `Tensor<Scalar>.sum()` is the preferred way to do this.
// TODO(TF-1030): Remove this and replace with `{ $0.sum() }`.
@differentiable
public func _sum<Scalar: TensorFlowFloatingPoint>(
    _ value: Tensor<Scalar>
) -> Tensor<Scalar> {
  return value.sum()
}

/// Workaround for TF-1030 so that we can use mean as a default argument for reductions.
/// `Tensor<Scalar>.mean()` is the preferred way to do this.
// TODO(TF-1030): Remove this and replace with `{ $0.mean() }`.
@differentiable
public func _mean<Scalar: TensorFlowFloatingPoint>(
    _ value: Tensor<Scalar>
) -> Tensor<Scalar> {
  return value.mean()
}
