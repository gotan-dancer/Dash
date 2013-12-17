class ScoresController < ApplicationController
  def create
    @score = Score.find_or_create_by(params.require(:score).permit(:name, :value))

    scores_above = Score.where("value > ?", @score.value).order(:value).limit(4).load
    scores_below = Score.where("value <= ? and id != ?", @score.value, @score.id).order("value DESC").limit(9 - scores_above.size).load

    render :json => {
      :scores => (scores_above + [@score] + scores_below).map do |score|
        {
          :name => score.name,
          :value => score.value,
          :current => (score == @score)
        }
      end
    }
  end
end
